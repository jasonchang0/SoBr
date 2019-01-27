/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Contains the main app implementation using Vision.
 */

import UIKit
import AVKit
import Vision

class FacialRecognitionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Main view for showing camera content.
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var drunkLabel: UILabel!
    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    // debug
    let debug: Bool = UserDefaults.standard.value(forKey: "debug") as! Bool
    
    // AVCapture variables to hold sequence data
    var session: AVCaptureSession?
    var currentPosition: AVCaptureDevice.Position?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?
    var currentFrame: UIImage?
    var currentFace: UIImage?
    
    var captureDevice: AVCaptureDevice?
    var captureDeviceResolution: CGSize = CGSize()
    
    // Layer UI for drawing Vision results
    var rootLayer: CALayer?
    var detectionOverlayLayer: CALayer?
    var detectedFaceRectangleShapeLayer: CAShapeLayer?
    
    // Vision requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var lastClassification: Date = Date(timeIntervalSinceNow: 0)
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    var active: Bool = true
    var unlocked = false
    
    // MARK: UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flipCameraButton.layer.cornerRadius = 10
        flipCameraButton.layer.masksToBounds = true
        
        print("Access token is \((UIApplication.shared.delegate as! AppDelegate).smartcar?.accessToken ?? "")")
        
        if !debug {
            faceImageView.isHidden = true
            drunkLabel.isHidden = true
            flipCameraButton.isHidden = true
        }
        
        progressView.progress = 0
        
        let blurEffect = UIBlurEffect(style: .extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = visualEffectView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        visualEffectView.addSubview(blurEffectView)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.session = self.setupAVCaptureSession(position: .front)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session?.startRunning()
        }
        self.prepareVisionRequest()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.teardownAVCapture()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Ensure that the interface stays locked in Portrait.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // Ensure that the interface stays locked in Portrait.
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    // MARK: AVCapture Setup
    
    /// - Tag: CreateCaptureSession
    fileprivate func setupAVCaptureSession(position: AVCaptureDevice.Position) -> AVCaptureSession? {
        currentPosition = position
        let captureSession = AVCaptureSession()
        do {
            let inputDevice = try self.configureCamera(for: captureSession, position: position)
            self.configureVideoDataOutput(for: inputDevice.device, resolution: inputDevice.resolution, captureSession: captureSession)
            self.designatePreviewLayer(for: captureSession)
            return captureSession
        } catch let executionError as NSError {
            self.presentError(executionError)
        } catch {
            self.presentErrorAlert(message: "An unexpected failure has occured")
        }
        
        self.teardownAVCapture()
        
        return nil
    }
    
    /// - Tag: ConfigureDeviceResolution
    fileprivate func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format? = nil
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)
        
        for format in device.formats {
            let deviceFormat = format as AVCaptureDevice.Format
            
            let deviceFormatDescription = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
                if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
                    highestResolutionFormat = deviceFormat
                    highestResolutionDimensions = candidateDimensions
                }
            }
        }
        
        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }
        
        return nil
    }
    
    fileprivate func configureCamera(for captureSession: AVCaptureSession, position: AVCaptureDevice.Position) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position)
        
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }
                
                if let highestResolution = self.highestResolution420Format(for: device) {
                    try device.lockForConfiguration()
                    device.activeFormat = highestResolution.format
                    device.unlockForConfiguration()
                    
                    return (device, highestResolution.resolution)
                }
            }
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    /// - Tag: CreateSerialDispatchQueue
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "net.Hoke.Sobr")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }
        
        self.videoDataOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue
        
        self.captureDevice = inputDevice
        self.captureDeviceResolution = resolution
    }
    
    /// - Tag: DesignatePreviewLayer
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer
        
        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.white.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        if let previewRootLayer = self.previewView?.layer {
            self.rootLayer = previewRootLayer
            
            previewRootLayer.masksToBounds = true
            videoPreviewLayer.frame = previewRootLayer.bounds
            previewRootLayer.insertSublayer(videoPreviewLayer, at: 0)
        }
    }
    
    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
        self.videoDataOutput = nil
        self.videoDataOutputQueue = nil
        detectedFaceRectangleShapeLayer?.removeFromSuperlayer()
        
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
    
    // MARK: Helper Methods for Error Presentation
    
    fileprivate func presentErrorAlert(withTitle title: String = "Unexpected Failure", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alertController, animated: true)
    }
    
    fileprivate func presentError(_ error: NSError) {
        self.presentErrorAlert(withTitle: "Failed with error \(error.code)", message: error.localizedDescription)
    }
    
    // MARK: Helper Methods for Handling Device Orientation & EXIF
    
    fileprivate func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
        return CGFloat(Double(degrees) * Double.pi / 180.0)
    }
    
    func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
            
        case .landscapeLeft:
            return .downMirrored
            
        case .landscapeRight:
            return .upMirrored
            
        default:
            return .leftMirrored
        }
    }
    
    func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }
    
    // MARK: Performing Vision Requests
    
    /// - Tag: WriteCompletionHandler
    fileprivate func prepareVisionRequest() {
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
            
            if error != nil {
                print("FaceDetection error: \(String(describing: error)).")
            }
            
            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                    return
            }
            
            DispatchQueue.main.async {
                self.handleFaceObservations(results)
                let now = Date(timeIntervalSinceNow: 0)
                if now.timeIntervalSince(self.lastClassification) >= 0.5 {
                    self.classifyDrunkenness()
                }
            }
            
        })
        
        // Start with detection.  Find face, then track it.
        self.detectionRequests = [faceDetectionRequest]
        
        self.sequenceRequestHandler = VNSequenceRequestHandler()
        
        self.setupVisionDrawingLayers()
    }
    
    // MARK: Drawing Vision Observations
    
    fileprivate func setupVisionDrawingLayers() {
        let captureDeviceResolution = self.captureDeviceResolution
        
        let captureDeviceBounds = CGRect(x: 0,
                                         y: 0,
                                         width: captureDeviceResolution.width,
                                         height: captureDeviceResolution.height)
        
        let captureDeviceBoundsCenterPoint = CGPoint(x: captureDeviceBounds.midX,
                                                     y: captureDeviceBounds.midY)
        
        let normalizedCenterPoint = CGPoint(x: 0.5, y: 0.5)
        
        guard let rootLayer = self.rootLayer else {
            self.presentErrorAlert(message: "view was not property initialized")
            return
        }
        
        let overlayLayer = CALayer()
        overlayLayer.name = "DetectionOverlay"
        overlayLayer.masksToBounds = true
        overlayLayer.anchorPoint = normalizedCenterPoint
        overlayLayer.bounds = captureDeviceBounds
        overlayLayer.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        
        let faceRectangleShapeLayer = CAShapeLayer()
        faceRectangleShapeLayer.name = "RectangleOutlineLayer"
        faceRectangleShapeLayer.bounds = captureDeviceBounds
        faceRectangleShapeLayer.anchorPoint = normalizedCenterPoint
        faceRectangleShapeLayer.position = captureDeviceBoundsCenterPoint
        faceRectangleShapeLayer.fillColor = nil
        faceRectangleShapeLayer.strokeColor = Constants.sobrRed.cgColor
        faceRectangleShapeLayer.lineWidth = 5
        faceRectangleShapeLayer.shadowOpacity = 0.7
        faceRectangleShapeLayer.shadowRadius = 5
        
        overlayLayer.addSublayer(faceRectangleShapeLayer)
        rootLayer.addSublayer(overlayLayer)
        
        self.detectionOverlayLayer = overlayLayer
        self.detectedFaceRectangleShapeLayer = faceRectangleShapeLayer
        
        self.updateLayerGeometry()
    }
    
    fileprivate func updateLayerGeometry() {
        guard let overlayLayer = self.detectionOverlayLayer,
            let rootLayer = self.rootLayer,
            let previewLayer = self.previewLayer
            else {
                return
        }
        
        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
        
        let videoPreviewRect = previewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        var rotation: CGFloat
        var scaleX: CGFloat
        var scaleY: CGFloat
        
        // Rotate the layer into screen orientation.
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            rotation = 180
            scaleX = videoPreviewRect.width / captureDeviceResolution.width
            scaleY = videoPreviewRect.height / captureDeviceResolution.height
            
        case .landscapeLeft:
            rotation = 90
            scaleX = videoPreviewRect.height / captureDeviceResolution.width
            scaleY = scaleX
            
        case .landscapeRight:
            rotation = -90
            scaleX = videoPreviewRect.height / captureDeviceResolution.width
            scaleY = scaleX
            
        default:
            rotation = 0
            scaleX = videoPreviewRect.width / captureDeviceResolution.width
            scaleY = videoPreviewRect.height / captureDeviceResolution.height
        }
        
        // Scale and mirror the image to ensure upright presentation.
        let affineTransform = CGAffineTransform(rotationAngle: radiansForDegrees(rotation))
            .scaledBy(x: scaleX, y: -scaleY)
        overlayLayer.setAffineTransform(affineTransform)
        
        // Cover entire screen UI.
        let rootLayerBounds = rootLayer.bounds
        overlayLayer.position = CGPoint(x: rootLayerBounds.midX, y: rootLayerBounds.midY)
        
    }
    
    fileprivate func addIndicators(to faceRectanglePath: CGMutablePath, for faceObservation: VNFaceObservation) {
        let displaySize = self.captureDeviceResolution
        
        var faceBounds = VNImageRectForNormalizedRect(faceObservation.boundingBox, Int(displaySize.width), Int(displaySize.height))
        
        if currentPosition == .back {
            faceBounds = CGRect(x: displaySize.width - faceBounds.maxX, y: faceBounds.minY, width: faceBounds.width, height: faceBounds.height)
        }
        
        faceRectanglePath.addRect(faceBounds)
        
    }
    
    fileprivate func handleFaceObservations(_ faceObservations: [VNFaceObservation]) {
        guard let faceRectangleShapeLayer = self.detectedFaceRectangleShapeLayer
            else {
                return
        }
        
        CATransaction.begin()
        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
        
        let faceRectanglePath = CGMutablePath()
        
        for faceObservation in faceObservations {
            self.addIndicators(to: faceRectanglePath,
                               for: faceObservation)
        }
        
        faceRectangleShapeLayer.path = faceRectanglePath
        
        self.updateLayerGeometry()
        
        CATransaction.commit()
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    /// - Tag: PerformRequests
    // Handle delegate method callback on receiving a sample buffer.
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if unlocked && self.presentedViewController == nil {
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        if drunkennessProbabilities.count >= 20 {
            // This means it is time to check for the final prediction.
            
            active = false
            var sum = 0.0
            for p in drunkennessProbabilities {
                sum += p
            }
            
            let avg = sum/Double(drunkennessProbabilities.count)
            
            if avg < 0.6 {
                
                let alertController = UIAlertController(title: "Unlocked", message: "Your vehicle has been unlocked.", preferredStyle: .alert)
                unlocked = true
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if let smartcar = appDelegate.smartcar {
                    smartcar.unlockVehicle()
                }
                let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                }
                alertController.addAction(action1)
                self.present(alertController, animated: true) {}
            } else {
                let alertController = UIAlertController(title: "Uh Oh", message: "It looks like you might not be fit to drive.", preferredStyle: .alert)
                let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                }
                alertController.addAction(action1)
                self.present(alertController, animated: true) {}
            }
            
            drunkennessProbabilities = []
            
        }
        
        var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
        
        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
        if cameraIntrinsicData != nil {
            requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let context = CIContext.init(options: nil)
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let exifOrientation = self.exifOrientationForCurrentDeviceOrientation()
        currentFrame = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        
        
        if let currentFrame = currentFrame {
            let ciImage = CIImage(cgImage: currentFrame.cgImage!)
            
            let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
            
            let faces = faceDetector.features(in: ciImage)
            
            if let face = faces.first as? CIFaceFeature {
                let bounds = CGRect(x: face.bounds.minX, y: currentFrame.size.height-face.bounds.maxY, width: face.bounds.width, height: face.bounds.height)
                currentFace = UIImage(cgImage: currentFrame.cgImage!.cropping(to: bounds)!, scale: 1, orientation: .right)
            }
            
            if faces.count == 0 {
                DispatchQueue.main.async {
                    self.drunkLabel.text = ""
                    self.currentFace = nil
                }
            }
        }
        
        // Perform initial detection
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                        orientation: exifOrientation,
                                                        options: requestHandlerOptions)
        do {
            guard let detectRequests = self.detectionRequests else {
                return
            }
            try imageRequestHandler.perform(detectRequests)
        } catch let error as NSError {
            NSLog("Failed to perform FaceRectangleRequest: %@", error)
        }
        
    }
    
    @IBAction func flipCameraPressed(_ sender: Any) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.session?.stopRunning()
        }
        
        self.teardownAVCapture()
        
        if currentPosition == .front {
            currentPosition = .back
        } else {
            currentPosition = .front
        }
        
        self.session = self.setupAVCaptureSession(position: currentPosition!)
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.session?.startRunning()
        }
        
        self.prepareVisionRequest()
        
    }
    
    var drunkennessProbabilities: [Double] = [] {
        didSet {
            DispatchQueue.main.async {
                self.progressView.progress = Float(self.drunkennessProbabilities.count) / 20.0
            }
        }
    }
    
    fileprivate func classifyDrunkenness() {
        
        if self.presentedViewController == nil { active = true }
        
        if active {
            if let currentFace = currentFace {
                if let pixels = buffer(from: currentFace) {
                    if let square = resizePixelBuffer(pixels, width: 106, height: 106) {
                        
                        let model = DrunkKerasModel_v10()
                        lastClassification = Date(timeIntervalSinceNow: 0)
                        
                        let ciImage = CIImage(cvImageBuffer: square)
                        let context = CIContext(options: nil)
                        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
                        faceImageView.image = UIImage(cgImage: cgImage)

                        DispatchQueue.global(qos: .userInteractive).async {
                            if let output = try? model.prediction(image: square) {
                                DispatchQueue.main.async {
                                    let probabilityOfDrunk = output.output["Drunk"] ?? 0
                                }
                            }
                        }
                        
                        var votes: [Int] = []
                        let v6 = DrunkKerasModel_v6()
                        DispatchQueue.global(qos: .userInteractive).async {
                            if let output = try? v6.prediction(image: square) {
                                DispatchQueue.main.async {
                                    let probabilityOfDrunk = output.output["Drunk"] ?? 0
                                    if probabilityOfDrunk > 0.6 {
                                        votes.append(1)
                                    } else {
                                        votes.append(0)
                                    }
                                }
                            }
                        }
                        
                        let v9 = DrunkKerasModel_v9()
                        DispatchQueue.global(qos: .userInteractive).async {
                            if let output = try? v9.prediction(image: square) {
                                DispatchQueue.main.async {
                                    let probabilityOfDrunk = output.output["Drunk"] ?? 0
                                    if probabilityOfDrunk > 0.6 {
                                        votes.append(1)
                                    } else {
                                        votes.append(0)
                                    }
                                }
                            }
                        }
                        
                        let v10 = DrunkKerasModel_v10()
                        DispatchQueue.global(qos: .userInteractive).async {
                            if let output = try? v10.prediction(image: square) {
                                DispatchQueue.main.async {
                                    let probabilityOfDrunk = output.output["Drunk"] ?? 0
                                    if probabilityOfDrunk > 0.6 {
                                        votes.append(1)
                                    } else {
                                        votes.append(0)
                                    }
                                }
                            }
                        }
                        
                        let v11 = DrunkKerasModel_v11()
                        DispatchQueue.global(qos: .userInteractive).async {
                            if let output = try? v11.prediction(image: square) {
                                DispatchQueue.main.async {
                                    let probabilityOfDrunk = output.output["Drunk"] ?? 0
                                    if probabilityOfDrunk > 0.6 {
                                        votes.append(1)
                                    } else {
                                        votes.append(0)
                                    }
                                }
                            }
                        }
                        
                        let v12 = DrunkKerasModel_v12()
                        DispatchQueue.global(qos: .userInteractive).async {
                            if let output = try? v12.prediction(image: square) {
                                DispatchQueue.main.async {
                                    let probabilityOfDrunk = output.output["Drunk"] ?? 0
                                    if probabilityOfDrunk > 0.6 {
                                        votes.append(1)
                                    } else {
                                        votes.append(0)
                                    }
                                }
                            }
                        }
                        
                        DispatchQueue.global(qos: .userInteractive).async {
                            while votes.count < 5 {}
                            DispatchQueue.main.async {
                                self.drunkLabel.text = " \(Double(votes.reduce(0, +)) / Double(votes.count))"
                            }
                            
                            if votes.reduce(0, +) > votes.count / 2 {
                                self.drunkennessProbabilities.append(1)
                            } else {
                                self.drunkennessProbabilities.append(0)
                            }
                        }
                        
                        
                    }
                }
            }
        }
    }
    
    fileprivate func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

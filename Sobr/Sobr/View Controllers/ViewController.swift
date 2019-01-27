//
//  ViewController.swift
//  Sobr
//
//  Created by Tanner Hoke on 1/26/19.
//  Copyright © 2019 Tanner Hoke. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var menuView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        } catch {
            print(error)
        }
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewView.addSubview(blurEffectView)
        
        testButton.layer.cornerRadius = 10
        testButton.clipsToBounds = true
        
        settingsButton.layer.cornerRadius = 10
        settingsButton.clipsToBounds = true
        
        menuView.layer.cornerRadius = 10
        menuView.clipsToBounds = true
        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24, weight: .light), NSAttributedString.Key.foregroundColor: Constants.sobrRed]
        navigationController?.navigationBar.tintColor = Constants.sobrRed
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.smartcar = SmartcarAuth(clientId: Constants.smartcarClientID, redirectUri: Constants.smartcarRedirectURI, scope: [], development: false, testMode: 1, completion: { (error: Error?, code: String?, state: String?) -> Any? in
            self.dismiss(animated: true, completion: nil)

            guard let code = code else {
                return nil
            }
            
            let authorizationHeader = "Basic " + ((Constants.smartcarClientID + ":" + Constants.smartcarClientSecret).data(using: .utf8)?.base64EncodedString() ?? "")
            let session = URLSession.shared
            let url = URL(string: "https://auth.smartcar.com/oauth/token")!
            
            //now create the URLRequest object using the url object
            var request = URLRequest(url: url)
            request.httpMethod = "POST" //set http method as POST
            request.httpBody = "redirect_uri=\(Constants.smartcarRedirectURI)&code=\(code)&grant_type=authorization_code".data(using: String.Encoding.utf8)
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.addValue(authorizationHeader, forHTTPHeaderField: "Authorization")
            
            //create dataTask using the session object to send data to the server
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
                guard error == nil else {
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    //create json object from data
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        appDelegate.smartcar?.accessToken = json["access_token"] as? String
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            })
            task.resume()
            return nil
        })
        
        // initialize authorization flow on the SFSafariViewController
        appDelegate.smartcar?.launchAuthFlow(state: nil, forcePrompt: false, viewController: self)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        captureSession?.stopRunning()
    }
    
    // Ensure that the interface stays locked in Portrait.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // Ensure that the interface stays locked in Portrait.
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

}


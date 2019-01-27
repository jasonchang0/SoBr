//
//  LaunchViewController.swift
//  Sobr
//
//  Created by Tanner Hoke on 1/27/19.
//  Copyright © 2019 Tanner Hoke. All rights reserved.
//

import UIKit
import LocalAuthentication

class LaunchViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Do any additional setup after loading the view.
        
        UserDefaults.standard.set(false, forKey: "debug")
        
        let context = LAContext()
        
        // First check if we have the needed hardware support.
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            
            let reason = "Log in to your account"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
                
                if success {
                    
                    // Move to the main thread because a state update triggers UI changes.
                    DispatchQueue.main.async {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "navigationController")
                        UIApplication.shared.keyWindow?.rootViewController = vc
                    }
                    
                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    
                    // Fall back to a asking for username and password.
                    // ...
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            
            // Fall back to a asking for username and password.
            // ...
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

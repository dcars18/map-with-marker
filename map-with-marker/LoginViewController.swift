//
//  LoginViewController.swift
//  map-with-marker
//
//  Created by David Carson on 4/3/17.
//  Copyright © 2017 William French. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore

class LoginViewController: UIViewController, LoginButtonDelegate {

    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        switch result{
        case .success(let _, let _, let accessToken):
            performSegue(withIdentifier: "postLoginSegue", sender: nil)
            //print(accessToken)
            //print("success")
        case .failed(let _):
            print("failed")
        case .cancelled:
            print("cancelled")
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("Logout")
    }


    
    override func viewDidLoad() {
        
        if AccessToken.current != nil{
            DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "postLoginSegue", sender: nil)
                })
        }

        let loginButton = LoginButton(readPermissions: [ .publicProfile, .email ])
        loginButton.delegate = self
        loginButton.center = view.center
        
        view.addSubview(loginButton)
    }
    
    
}

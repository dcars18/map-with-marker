//
//  LoginViewController.swift
//  map-with-marker
//
//  Created by David Carson on 4/3/17.
//  Copyright © 2017 William French. All rights reserved.
//

import UIKit
import CoreLocation
import FacebookLogin
import FacebookCore

class LoginViewController: UIViewController, LoginButtonDelegate, CLLocationManagerDelegate {
      var locationManager:CLLocationManager!

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
    
    //Prepare for segues to event details view and create event view...
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "postLoginSegue" {
            if let toViewController = segue.destination as? ViewController {
                print("Prepare for Main View")
                
                    
//                self.determineCurrentLocation(){ response in
//                        print("\(response.latitude), \(response.longitude)")
//                        toViewController.userLat = response.latitude
//                        toViewController.userLong = response.longitude
//                }
            }
        }
    }
    
    func determineCurrentLocation(completion: @escaping (CLLocationCoordinate2D)->Void)
    {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            
            completion((locationManager.location?.coordinate)!)
        }
    }
}

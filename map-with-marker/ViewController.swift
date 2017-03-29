/*
 * Copyright 2016 Google Inc. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import UIKit
import GoogleMaps
import Gloss

struct Event {
    let _id: String
    let marker: GMSMarker
}

class ViewController: UIViewController {

  override func loadView() {
    
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate -33.86,151.20 at zoom level 6.
//    let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
//    let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
//    view = mapView
    

    let array = getAllEvents()

  }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        //Code for adding a button to view
        let button = UIButton(frame: CGRect(x: 230, y: 20, width: 110, height: 50))
        button.backgroundColor = UIColor.gray
        button.setTitle("Refresh", for: .normal)
        button.addTarget(self, action: #selector(createButtonTapped(button:)), for: .touchUpInside)
        self.view.addSubview(button)
        
        
        let addButton = UIButton(frame: CGRect(x: 30, y: 20, width: 110, height: 50))
        addButton.backgroundColor = UIColor.blue
        addButton.setTitle("Join Event", for: .normal)
        addButton.addTarget(self, action: #selector(addUserButtonTapped(button:)), for: .touchUpInside)
        self.view.addSubview(addButton)
        
    }

    func getAllEvents() -> [Event]
    {
        //Reset Map stuff
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView

        var temp = [Event]()
        self.getJson(service: "http://localhost:3000/eventServices/getAllEvents") {response in
            //print(response)
            DispatchQueue.main.async {
                for event in response
                {
                    let marker = GMSMarker()
                    let i = event["eventType"] as? Int
                    if(i == 2){
                        marker.icon = GMSMarker.markerImage(with: .black)
                    }
                    else if(i == 3){
                        marker.icon = GMSMarker.markerImage(with: .red)
                    }
                    else{
                        marker.icon = GMSMarker.markerImage(with: .cyan)
                    }
                    
                    marker.position = CLLocationCoordinate2D(latitude: event["lat"] as! CLLocationDegrees, longitude: event["long"] as! CLLocationDegrees)
                    marker.title = event["eventName"] as! String?
                    marker.snippet = event["eventDescription"] as! String?
                    marker.map = mapView
                    
                    let event = Event(_id: event["_id"] as! String, marker: marker)
                    
                    temp.append(event)
                }
                self.viewDidLoad()
            }
        }
        return temp
    }
    
    func getJson(service: String, completion: @escaping ([Dictionary<String,Any>])->Void)
    {
        let url = URL(string: service)
        
        
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
            let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [Dictionary<String,Any>]
            //let e = Event(json: json)
            //print(json[0]["eventName"]!)
            
            //return json as [Dictionary<String, Any>]
            completion(json)
        }
        
        task.resume()
        
    }
    
    func createButtonTapped(button: UIButton)
    {
        getAllEvents()
    }
    
    func addUser(){
        self.sendJson(service: "http://localhost:3000/userServices/addUserToEvent"){ response in
            print(response)
        }
    }
    
    func addUserButtonTapped(button: UIButton)
    {
        addUser()
    }
    
    func sendJson(service: String, completion: @escaping ([String:Any])->Void)
    {
        // prepare json data
        let json: [String: Any] = ["eventID": "58d50ff3cb138032771b91cc",
                                   "email": "erin.combs@uky.edu", "name": "Erin Combs", "eventDate": "03-24-2017"]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let url = URL(string: service)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            completion(responseJSON)
            }
        }
        
        task.resume()
        
    }

}


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
import FacebookCore

struct Event {
    let _id: String
    let marker: GMSMarker
}


let accessToken = AccessToken.current
var userEmail = ""
var usersName = ""
var eventList = [Event]()
var tappedMarker = ""
var longPressedCoord = CLLocationCoordinate2D()

var baseURL = "http://bloodroot.cs.uky.edu:3000/"

class ViewController: UIViewController, GMSMapViewDelegate {

  override func loadView() {
    
    // Create a GMSCameraPosition that tells the map to display the
    // coordinate -33.86,151.20 at zoom level 6.
//    let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
//    let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
//    view = mapView


    getAllEvents()

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

        //Use facebook graph api to get email which is primary key, store in global variable
        let params = ["fields" : "email, name"]
        let graphRequest = GraphRequest(graphPath: "me", parameters: params)
        graphRequest.start {
            (urlResponse, requestResult) in
            
            switch requestResult {
            case .failed(let error):
                print("error in graph request:", error)
                break
            case .success(let graphResponse):
                if let responseDictionary = graphResponse.dictionaryValue {
                    
                    //print(responseDictionary["name"])
                    //print(responseDictionary["email"])
                    userEmail = responseDictionary["email"] as! String
                    usersName = responseDictionary["name"] as! String
                }
            }
        }
        
    }

    func getAllEvents()
    {
        //Reset Map stuff
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = self
        view = mapView

        var temp = [Event]()
        self.getJson(service: "http://bloodroot.cs.uky.edu:3000/eventServices/getAllEvents") {response in
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
                eventList = temp
            }
        }
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
        //print(eventList)
    }
    
    func addUser(){
        if(tappedMarker != ""){
            
            let json: [String: Any] = ["eventID": tappedMarker, "email": userEmail, "name": usersName]
            self.sendJson(service: "http://bloodroot.cs.uky.edu:3000/userServices/addUserToEvent", json: json){ response in
                DispatchQueue.main.async {

                }
            }
            let alert = UIAlertController(title: "Success", message: "Successfully Added to Event", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func addUserButtonTapped(button: UIButton)
    {
        addUser()
    }
    
    func sendJson(service: String, json: [String: Any], completion: @escaping ([[String:Any]])->Void)
    {
        // prepare json data
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
            if let newJson = responseJSON as? [[String: Any]] {
                print(newJson)
                completion(newJson)
            }
        }
        
        task.resume()
        
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        for event in eventList {
            if(event.marker == marker){
                tappedMarker = event._id
            }
        }
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        //Create Json right before sending
        let json: [String: Any] = ["eventID": tappedMarker]
        self.sendJson(service: "http://bloodroot.cs.uky.edu:3000/userServices/getAllUsersForEvent", json: json){ response in
            DispatchQueue.main.async{
                //print(response)
                self.performSegue(withIdentifier: "eventDetailsSegue", sender: nil)
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        print("didLongPressAt")
        DispatchQueue.main.async{
            longPressedCoord = coordinate
            self.performSegue(withIdentifier: "createEventSegue", sender: nil)
        }

    }
    
    
    //Prepare for segues to event details view and create event view...
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "eventDetailsSegue" {
            
            if let toViewController = segue.destination as? EventDetailsViewController {
                print("Prepare for Event Details View")
            }
        }
        
        else if segue.identifier == "createEventSegue" {
            if let toViewController = segue.destination as? CreateEventViewController {
                print("Prepare for CreateEvent View")
                toViewController.coordinate = longPressedCoord
                toViewController.eventCreator = userEmail
            }
        }
    }

}

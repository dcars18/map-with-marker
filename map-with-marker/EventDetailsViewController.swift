//
//  EventDetailsViewController.swift
//  map-with-marker
//
//  Created by David Carson on 4/15/17.
//  Copyright © 2017 William French. All rights reserved.
//

import UIKit
import GoogleMaps

class EventDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    //var baseURL = "http://bloodroot.cs.uky.edu:3000"
    var baseURL = "http://localhost:3000"
    var eventID = ""
    var eventData = [[String: Any]]()
    var attendingData = [[String: Any]]()
    var currentUser = ""
    
    var indicator = UIActivityIndicatorView()
    
    @IBOutlet weak var streetAddr: UITextView!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var eventStart: UILabel!
    @IBOutlet weak var eventEnd: UILabel!
    @IBOutlet weak var eventDescription: UITextView!
    
    @IBOutlet weak var attendingTable: UITableView!
    @IBOutlet weak var leaveEvent: UIButton!
    
    let geocoder = GMSGeocoder()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        activityIndicator()
        indicator.startAnimating()
        
        self.attendingTable.delegate = self
        self.attendingTable.dataSource = self
        
        leaveEvent.alpha = 0.0
        
        getAllDataForEvent()
        
    }
    
    //Performs 2 Web Service Calls to get data for populating table and event details
    func getAllDataForEvent(){
        
        let json: [String: Any] = ["eventID": eventID]
        
        self.sendJson(service: "\(baseURL)/eventServices/getAllEventInfo", json: json){ response in
            
            DispatchQueue.main.async {
                self.eventData = response as! [[String: Any]]
            
                //Set up event labels and data to show user info about event
                for event in self.eventData{
                    
                    self.eventName.text = event["eventName"] as? String
                    self.eventDescription.text = event["eventDescription"] as? String
                    self.eventStart.text = event["eventStartDate"] as? String
                    self.eventEnd.text = event["eventEndDate"] as? String
                    
                    //Allow eventcreators to delete their own events...
                    if(self.currentUser == event["eventCreator"] as! String)
                    {
                        self.deleteButton.isEnabled = true
                    }
                    
                    
                    let coordinates = CLLocationCoordinate2DMake(event["lat"] as! CLLocationDegrees, event["long"] as! CLLocationDegrees)
                    self.geocoder.reverseGeocodeCoordinate(coordinates){ response , error in
                        DispatchQueue.main.async {
                            if let address = response?.firstResult() {
                                if(address.lines?[0] != "")
                                {
                                    self.streetAddr.text = address.lines?[0]
                                }
                                else
                                {
                                    self.streetAddr.text = "Sorry we couldn't find an address for this Event Location!"
                                }
                            }
                            else
                            {
                                self.streetAddr.text = "Sorry we couldn't find an address for this Event Location!"
                            }
                        }
                    }
                    
                }
                self.indicator.stopAnimating()
            }
        }
        
        self.sendJson(service: "\(baseURL)/userServices/getAllUsersForEvent", json: json){ response in
            DispatchQueue.main.async {
                self.attendingData = response as! [[String:Any]]
                //Load data into table view and stop activity indicator...
                self.attendingTable.reloadData()
            }
        }
    }
    
    //Function that sends JSON as a POST HTTP request. Can either return JSON or a string
    //Some API calls return nothing some return data after post so unwrap accordingly
    func sendJson(service: String, json: [String: Any], completion: @escaping (Any)->Void)
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
            if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []){
                completion(responseJSON)
            }
            else
            {
                completion("NO JSON RETURNED")
            }
        }
        
        task.resume()
        
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attendingData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Getting the right element
        let attendee = attendingData[indexPath.row]
        
        // Instantiate a cell
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Attending Call")
        
        // Adding the right informations
        cell.textLabel?.text = attendee["name"] as? String
        cell.detailTextLabel?.text = attendee["email"] as? String
        
        if(currentUser == attendee["email"] as! String)
        {
            print("This happens...")
            leaveEvent.isEnabled = true
            leaveEvent.alpha = 1.0
        }
        
        // Returning the cell
        return cell
    }
    
    //Make the title for the table the event creator's email
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        for event in eventData
        {
            if(event["eventCreator"] != nil)
            {
                return "Creator: \(event["eventCreator"] as! String)"
            }
        }
        return "Sorry there's a problem getting Event Creator!"
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        let refreshAlert = UIAlertController(title: "Delete", message: "Are You Sure you want to delete this event? This cannot be undone!", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            let json: [String: Any] = ["_id": self.eventID, "eventCreator": self.currentUser]
            self.sendJson(service: "\(self.baseURL)/eventServices/deleteEvent", json: json){response in
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "returnToMapFromEventDetails", sender: nil)
                }
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    //Sets up Activity Indicator to let user know loading is happening...
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0.0, y: 0.0, width: 60.0, height: 60.0))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.backgroundColor = UIColor.darkGray.withAlphaComponent(0.6)
        indicator.hidesWhenStopped = true
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    //Leave the event, and reload the table data so that the user is dynamically removed from the list after the callback
    //Using the completion handler
    @IBAction func leaveEventAction(_ sender: Any) {
        
        let leaveEventAlert = UIAlertController(title: "Leave Group", message: "Are You Sure you want to leave this event?", preferredStyle: UIAlertControllerStyle.alert)
        
        leaveEventAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            let json: [String: Any] = ["eventID": self.eventID, "email": self.currentUser]
            self.sendJson(service: "\(self.baseURL)/userServices/removeUserFromEvent", json: json){response in
                DispatchQueue.main.async {
                    //This will filter out the current user after they leave the group that way the table can update itself
                    //Without having to leave the screen or having to reload the event data
                    self.attendingData = self.attendingData.filter{$0["name"] as! String == self.currentUser && $0["eventID"] as! String == self.eventID}
                    self.attendingTable.reloadData()
                    
                }
            }
        }))
        
        leaveEventAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        present(leaveEventAlert, animated: true, completion: nil)
    }
    
}

//
//  createEventViewController.swift
//  map-with-marker
//
//  Created by David Carson on 4/15/17.
//  Copyright © 2017 William French. All rights reserved.
//

import UIKit
import GoogleMaps

class CreateEventViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource{
    
    @IBOutlet weak var eventName: UITextField!
    
    @IBOutlet weak var eventDescription: UITextField!
    
    @IBOutlet weak var startTime: UIDatePicker!
    @IBOutlet weak var endTime: UIDatePicker!
    @IBOutlet weak var eventType: UIPickerView!
    @IBOutlet weak var createButton: UIButton!
    
    var eventCreator = ""
    var coordinate = CLLocationCoordinate2D()
    
    var pickerData: [String] = [String]()
    var currentlyPicked = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Connect data:
        self.eventType.delegate = self
        self.eventType.dataSource = self
        
        //These values will populate our pickerview
        pickerData = ["Social", "Sports", "Gaming"]
        currentlyPicked = 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Datasource required functions
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // Delegate required Functions
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentlyPicked = row+1
    }
    @IBAction func createEvent(_ sender: Any) {
        
        var userEvent = [String: Any]()
        
        //Basic Data Validation
        if let eventNameText = eventName.text, !eventNameText.isEmpty
        {
            if eventNameText.characters.count < 5 || eventNameText.characters.count > 20
            {
                //Insert Alert Box
            }
            //Add to Json object to be sent...
            userEvent["eventName"] = eventNameText
        }
        if let eventDescText = eventDescription.text, !eventDescText.isEmpty
        {
            if eventDescText.characters.count > 140
            {
                //Insert Alert Box too long
            }
            //Add to Json object to be sent...
            userEvent["eventDescription"] = eventDescText
        }
        
        //Check to make sure the dates are not before current time and that the end date is not before the start date
        let date = Date()
        if (startTime.date >= date && endTime.date > startTime.date)
        {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            let startDateString = dateFormatter.string(from: startTime.date)
            let endDateString = dateFormatter.string(from: endTime.date)
            //Add to the Json object to be sent...
            userEvent["eventStartDate"] = startDateString
            userEvent["eventEndDate"] = endDateString
        }
        else
        {
            //Insert Alert Box
        }
        
        userEvent["eventType"] = currentlyPicked
        userEvent["lat"] = coordinate.latitude
        userEvent["long"] = coordinate.longitude
        userEvent["eventCreator"] = eventCreator
        
     
        self.sendJson(service: "http://bloodroot.cs.uky.edu:3000/eventServices/createEvent", json: userEvent){ response in
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "returnToMap", sender: nil)
            }
        }
        
    }
    
    
    func sendJson(service: String, json: [String: Any], completion: @escaping (String)->Void)
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
            }
            completion("Success")
        }
        
        task.resume()
        
    }
    
}
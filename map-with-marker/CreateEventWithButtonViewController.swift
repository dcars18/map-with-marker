//
//  CreateEventWithButtonViewController.swift
//  map-with-marker
//
//  Created by David Carson on 4/19/17.
//  Copyright © 2017 William French. All rights reserved.
//

import UIKit
import GoogleMaps


class CreateEventWithButtonViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var eventDescription: UITextField!
    @IBOutlet weak var eventAddress: UITextField!
    
    @IBOutlet weak var eventType: UIPickerView!
    
    @IBOutlet weak var startTime: UIDatePicker!
    @IBOutlet weak var endTime: UIDatePicker!
    @IBOutlet weak var createButton: UIButton!
    
    let geocoder = CLGeocoder()
    
    
    var pickerData: [String] = [String]()
    var currentlyPicked = 0
    
    var eventCreator = ""
    var coordinate = CLLocationCoordinate2D()
    
    //var baseURL = "http://bloodroot.cs.uky.edu:3000"
    var baseURL = "http://localhost:3000"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        coordinate.latitude = 0.0
        coordinate.longitude = 0.0
        // Connect data:
        self.eventType.delegate = self
        self.eventType.dataSource = self
        
        self.eventName.delegate = self
        self.eventDescription.delegate = self
        
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
                //print(newJson)
            }
            completion("Success")
        }
        
        task.resume()
        
    }
    
    @IBAction func createButtonPressed(_ sender: Any) {
        var validator = validateCreateEventData()
        if(validator.isValid)
        {
            geocoder.geocodeAddressString(eventAddress.text!){ (placemarks, error) in
                if(error == nil)
                {
                    validator.userEvent["lat"] = placemarks?.first?.location?.coordinate.latitude
                    validator.userEvent["long"] = placemarks?.first?.location?.coordinate.longitude
                    
                    //print(validator)
                    self.sendJson(service: "\(self.baseURL)/eventServices/createEvent", json: validator.userEvent){ response in
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "returnToMapFromCreateButton", sender: nil)
                            }
                    }
                }
                else
                {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Oops!", message: "We couldn't find your location! Please make sure you include Country and area code for better results!", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func validateCreateEventData() -> (isValid: Bool, userEvent: [String: Any])
    {
        var userEvent = [String: Any]()
        
        //Basic Data Validation
        if let eventNameText = eventName.text, !eventNameText.isEmpty
        {
            if eventNameText.characters.count < 5 || eventNameText.characters.count > 20
            {
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(title: "Oops!", message: "Event Name's Must be at least 5 letters long. And no longer than 20!", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return (false, userEvent)
            }
            //Add to Json object to be sent...
            userEvent["eventName"] = eventNameText
            if let eventDescText = eventDescription.text, !eventDescText.isEmpty
            {
                if eventDescText.characters.count > 140
                {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Oops!", message: "Event Descriptions can't be longer than 140 characters!", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    return (false, userEvent)
                }
                //Add to Json object to be sent...
                userEvent["eventDescription"] = eventDescText
                
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
                    
                    userEvent["eventType"] = currentlyPicked
                    userEvent["eventCreator"] = eventCreator
                    return (true, userEvent)
                    
                }
                else
                {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Oops!", message: "Event Date Invalid!", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    return (false, userEvent)
                }
            }
        }
        return (false, userEvent)
    }
    
    
    //Allows users to exit text entry with press of return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

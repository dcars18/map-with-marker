//
//  createEventViewController.swift
//  map-with-marker
//
//  Created by David Carson on 4/15/17.
//

import UIKit
import GoogleMaps

//Adds ability to tap anywhere not on the keyboard to exit text entry...
//Add function to any view controller to add functionality
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

class CreateEventViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate{
    
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
    
    //var baseURL = "bloodroot.cs.uky.edu:3000"
    var baseURL = "localhost:3000"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

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
    
    @IBAction func createEvent(_ sender: Any) {
        

        
        let validator = validateCreateEventData()
        if(validator.isValid)
        {
        self.sendJson(service: "http://\(baseURL)/eventServices/createEvent", json: validator.userEvent){ response in
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "returnToMap", sender: nil)
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
                    userEvent["lat"] = coordinate.latitude
                    userEvent["long"] = coordinate.longitude
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
    
    //Allows users to exit text entry with press of return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}

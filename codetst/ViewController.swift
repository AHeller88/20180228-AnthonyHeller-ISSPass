//
//  ViewController.swift
//  codetst
//
//  Created by Anthony M Heller on 2/18/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    var runonce = false;
    var locationManager = CLLocationManager()
    var outlist = [String: String]()
    
    
    @IBOutlet weak var uiLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            
            locationManager.startUpdatingLocation()
            //runs didUpdateLocations function
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //gets gps of device and sends it to function apiCall
        guard let locVal: CLLocationCoordinate2D = manager.location?.coordinate else {return}
        apiCall(loc: locVal)
    }
    
    func apiCall(loc: CLLocationCoordinate2D) {
        //calls api.open-notify.org, errors out if it can't convert it to url, if the api doesn't respond or responds with nothing
        
        
        //cheap hack to only call once
        if(runonce == false){
            runonce = true
        } else {
            return
        }
        
        //note, had to allow arbitary loads for url to work, from my understanding this is bad practice and a potential security flaw
        let endpoint : String = "http://api.open-notify.org/iss-pass.json?lat=\(loc.latitude)&lon=\(loc.longitude)"
        guard let urltosend = URL(string: endpoint) else {
            print("couldn't make url")
            return
        }
        let urlReq = URLRequest(url: urltosend)
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: urlReq) {data,response,error in
            guard error == nil else {
                print("error, on getting api response")
                return
            }
            guard let responseData = data else {
                print("error, no data")
                return
            }
            
            //serializes response (im pretty sure I'm doing this in a convaluted way) and drills down to get the duration of the pass and time stamp, then adds it as a key/value to global var outlist, then calls output function
            let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject]
            
           let response = json!!["response"] as! NSArray
            
            for objects in response {
                let temp = objects as! NSDictionary
                let dur = temp.allValues[0]
                let rise = temp.allValues[1]
                self.outlist["\(dur)"] = "\(rise)"
            }
            self.output()
            
        }
        task.resume()
    }
    
    func output() {
        //takes values in outlist dictionary, converts the timestamp to readable and outputs it to uilabel
        for (key, value) in outlist {

            let test = Double(value)
            let dateformatter = DateFormatter()
            dateformatter.dateStyle = .medium
            dateformatter.timeStyle = .short
            dateformatter.locale = Locale(identifier: "en_US")

            let date = NSDate(timeIntervalSince1970: test!)
            let prinDate = dateformatter.string(from: date as Date)
            
            //changing ui has to be done on main thread
            DispatchQueue.main.async {
                self.uiLabel.text = self.uiLabel.text! + "\n\nOn \(prinDate), the ISS will be above for \(key) seconds."
            }
            //console print for testing
            //print("On \(prinDate), the ISS will be above for \(key) seconds.")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}























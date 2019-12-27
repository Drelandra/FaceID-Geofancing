//
//  ViewController.swift
//  FaceID
//
//  Created by Bobby Yusuf Hoksono on 17/09/19.
//  Copyright © 2019 Bobby Yusuf Hoksono. All rights reserved.
//

import UIKit
import LocalAuthentication
import UserNotifications
import CoreLocation
import MapKit

enum AuthenticationState{
    case loggedin, loggedout
}

var context = LAContext()

class ViewController: UIViewController, CLLocationManagerDelegate, UNUserNotificationCenterDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var faceIDLabel: UILabel!
    @IBOutlet weak var stateView: UIView!
    
    var state = AuthenticationState.loggedout{
        didSet{
            loginButton.isHighlighted = state == .loggedin  // The button text changes on highlight.`
           self.view.backgroundColor = state == .loggedin ? .green : .red
            // FaceID runs right away on evaluation, so you might want to warn the user.`
            //  In this app, show a special Face ID prompt if the user is logged out, but`
            //  only if the device supports that kind of authentication.`
            faceIDLabel.isHidden = (state == .loggedin) || (context.biometryType != .faceID)
        }
        
    }
    @IBAction func tapButton(_ sender: Any) {
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            
            let reason = "Log in to your account"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
                if success {
                    
                    // Move to the main thread because a state update triggers UI changes.
                    DispatchQueue.main.async { [unowned self] in
                        self.state = .loggedin
                        
                    }
                }
                    
                    //ELSE
                else {
                    
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    // Fall back to a asking for username and password.`
                    // ...`
                }
            }
        }
        
        if state == .loggedin
        {
            state = .loggedout
        }
        else {
            
            // Get a fresh context for each login. If you use the same context on multiple attempts`
            //  (by commenting out the next line), then a previously successful authentication`
            //  causes the next policy evaluation to succeed without testing biometry again.`
            //  That's usually not what you want.
            context = LAContext()
            context.localizedCancelTitle = "Enter Username/Password"
            
        }
}
    
    //
    // For Notification based on Location
    var locationManager:CLLocationManager = CLLocationManager()
    let appleAcademyLocation = CLLocation(latitude: -6.294985 as CLLocationDegrees, longitude:106.641842 as CLLocationDegrees)
 //   let regionRadius: CLLocationDistance = 5
    let center = UNUserNotificationCenter.current()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The biometryType, which affects this app s UI when state changes, is only meaningful
        //  after running canEvaluatePolicy. But make sure not to run this test from inside a
        //  policy evaluation callback (for example, don t put next line in the state s didSet
        //  method, which is triggered as a result of the state change made in the callback),
        //  because that might result in deadlock.
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        // For notification based on location
        requestPermissionNotifications()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    //   mapViewLoad.showsUserLocation = true
        locationManager.distanceFilter = 100
        
        let geoFenceRegion: CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2DMake(-6.295152,106.641767), radius: 20, identifier: "AppleAcademy")
        locationManager.startMonitoring(for: geoFenceRegion)
        //locationManager.stopUpdatingLocation()
        // Do any additional setup after loading the view.
        
        // Check for Location Services
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        
        //Zoom to user location
//        if let userLocation = locationManager.location?.coordinate {
//            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
//            mapViewLoad.setRegion(viewRegion, animated: false)
//        }
        
        //   self.locationManager = locationManager
        
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
   }
    
    //   Drawing circle perimeters
//    func addRadiusCircle(location: CLLocation){
//        self.mapViewLoad.delegate = self as MKMapViewDelegate
//        let circle = MKCircle(center: appleAcademyLocation.coordinate, radius: 10 as CLLocationDistance)
//        self.mapViewLoad.addOverlay(circle)
//    }
//
//    func mapView(_ mapView: MKMapView!, rendererFor overlay: MKOverlay!) -> MKOverlayRenderer! {
//        if overlay is MKCircle {
//            let circle = MKCircleRenderer(overlay: overlay)
//            circle.strokeColor = UIColor.red
//            circle.fillColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.1)
//            circle.lineWidth = 1
//            return circle
//        } else {
//            return nil
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //    addRadiusCircle(location: appleAcademyLocation)
        
        for currentLocation in locations {
            print("\(String(describing: index)): \(currentLocation)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered: \(region.identifier)")
        postLocalNotifications(eventTitle:"Entered: \(region.identifier) Please Clock-In")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited: \(region.identifier)")
        postLocalNotifications(eventTitle:"Exited: \(region.identifier) Please Clock-Out")
    }
    
    func requestPermissionNotifications(){
        let application =  UIApplication.shared
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (isAuthorized, error) in
                if( error != nil ){
                    print(error!)
                }
                else{
                    if( isAuthorized ){
                        print("authorized")
                        NotificationCenter.default.post(Notification(name: Notification.Name("AUTHORIZED")))
                    }
                    else{
                        let pushPreference = UserDefaults.standard.bool(forKey: "PREF_PUSH_NOTIFICATIONS")
                        if pushPreference == false {
                            let alert = UIAlertController(title: "Turn on Notifications", message: "Push notifications are turned off.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Turn on notifications", style: .default, handler: { (alertAction) in
                                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                    return
                                }
                                
                                if UIApplication.shared.canOpenURL(settingsUrl) {
                                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                        // Checking for setting is opened or not
                                        print("Setting is opened: \(success)")
                                    })
                                }
                                UserDefaults.standard.set(true, forKey: "PREF_PUSH_NOTIFICATIONS")
                            }))
                            alert.addAction(UIAlertAction(title: "No thanks.", style: .default, handler: { (actionAlert) in
                                print("user denied")
                                UserDefaults.standard.set(true, forKey: "PREF_PUSH_NOTIFICATIONS")
                            }))
                            let viewController = UIApplication.shared.keyWindow!.rootViewController
                            DispatchQueue.main.async {
                                viewController?.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
        else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
    }
    
    func postLocalNotifications(eventTitle:String){
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = eventTitle
        content.body = "Please Click This Message to Clock In/Out"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let notificationRequest:UNNotificationRequest = UNNotificationRequest(identifier: "Region", content: content, trigger: trigger)
        
        center.add(notificationRequest, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
                print(error)
            }
            else{
                print("added")
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
//VC closing
}


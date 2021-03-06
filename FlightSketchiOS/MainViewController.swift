//
//  ViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/16/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import CoreLocation


class MainViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var menuTrailingConst: NSLayoutConstraint!
    @IBOutlet weak var currentAltitudeLabel: UILabel!
    @IBOutlet weak var maxAltitudeLabel: UILabel!
    @IBOutlet weak var sensorTempLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var battVLabel: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var recordBt: UIButton!
    @IBOutlet weak var armForLaunchBt: UIButton!
    @IBOutlet weak var openConnectionsBt: UIButton!
    
    let locationManager = CLLocationManager()
    
    @IBAction func setZeroAlt(_ sender: Any) {
        print("button")
        NotificationCenter.default.post(name: .setZeroAlt, object: self)
    }
    @IBAction func startRecording(_ sender: Any) {
        NotificationCenter.default.post(name: .recordData, object: self)
    }
    @IBAction func downloadData(_ sender: Any) {
        NotificationCenter.default.post(name: .downloadData, object: self)
    }
    @IBAction func openConnections(_ sender: UIButton) {
        
    }
    
    
    var menuShowing = false
    var connectionController: BLEConnectionModelController = BLEConnectionModelController()
    var deviceController: FSdeviceModelController = FSdeviceModelController()
    var userController: FSUsersModelController = FSUsersModelController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTrailingConst.constant = -200
        NotificationCenter.default.addObserver(self, selector: #selector(FSDeviceUpdate(_:)), name: .FSDeviceUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FSUserUpdate(_:)), name: .FSUserUpdate, object: nil)
        
        userController.getKeychainToken()
        userController.tryToken()
        
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        deviceController.FSDevice.location = locValue
    }
    
    @objc func FSUserUpdate(_ notification: NSNotification) {
        if (FSUser.sharedInstance.userName == "" || FSUser.sharedInstance.userName == nil){
            usernameLabel.text = "Not Logged In"
        }
        else {
            usernameLabel.text = "Logged in as " + FSUser.sharedInstance.userName!
        }
    }
    
    @objc func FSDeviceUpdate(_ notification: NSNotification) {
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            if let data = dict["data"] as? FSDeviceModel{
                //print("dataRx:" + data.base64EncodedString())
                if (data.currentAltitude == nil){
                    currentAltitudeLabel.text = "-----.-"
                }
                else {
                    currentAltitudeLabel.text = String(format: "%.1f", Double(data.currentAltitude!))
                }
                if (data.maxAltitude == nil){
                    maxAltitudeLabel.text = "-----.-"
                }
                else {
                    maxAltitudeLabel.text = String(format: "%.1f", Double(data.maxAltitude!))
                }
                if (data.temp == nil){
                    sensorTempLabel.text = "-----.-"
                }
                else {
                    sensorTempLabel.text = String(format: "%.1f", Double(data.temp!))
                }
                if (data.battVoltage == nil){
                    battVLabel.text = "-----.-"
                }
                else {
                    battVLabel.text = String(format: "%.2f", Double(data.battVoltage!))
                }
                if (BLEConnection.sharedInstance.connectedDevice == nil){
                    RSSILabel.text = "---"
                }
                else {
                    RSSILabel.text = BLEConnection.sharedInstance.deviceList[(BLEConnection.sharedInstance.controller?.deviceIndex())!].RSSI.stringValue
                }
                //if (data.isRecording) {
                //    recordBt.setTitle( "Recording" , for: .normal )
                //    recordBt.titleLabel?.textColor = UIColor.green
                //}
                //else {
                //    recordBt.setTitle( "Start Recording" , for: .normal )
                //    recordBt.titleLabel?.textColor = UIColor.white
                //}
                if (BLEConnection.sharedInstance.connectedDevice == nil){
                    openConnectionsBt.setTitle( "Connect to Device" , for: .normal )
                }
                else {
                openConnectionsBt.setTitle( BLEConnection.sharedInstance.connectedDevice?.name , for: .normal )
                    openConnectionsBt.titleLabel?.adjustsFontSizeToFitWidth = true
                    openConnectionsBt.titleLabel?.textColor = UIColor.green
                }
                if (data.isArmedForLaunch) {
                    armForLaunchBt.setTitle( "Ready To Launch" , for: .normal )
                    armForLaunchBt.titleLabel?.textColor = UIColor.green
                }
                else {
                    armForLaunchBt.setTitle( "Arm For Launch" , for: .normal )
                    armForLaunchBt.titleLabel?.textColor = UIColor.white
                }
                
            }
        }
    }
    
    
    @IBAction func toggleMenu(_ sender: Any) {
        if menuShowing {
            menuTrailingConst.constant = -200
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            })
        }
        else {
            menuTrailingConst.constant = 0
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
                })
        }
        
        menuShowing = !menuShowing
        
    }
    
}

extension Notification.Name {
    static let tn = Notification.Name("tn")
    static let deviceListChanged = Notification.Name("deviceListChanged")
    static let BLEDataRx = Notification.Name("BLEDataRx")
    static let FSDeviceUpdate = Notification.Name("FSDeviceUpdate")
    static let FSUserUpdate = Notification.Name("FSUserUpdate")
    static let setZeroAlt = Notification.Name("setZeroAlt")
    static let sendBLEPacket = Notification.Name("sendBLEPacket")
    static let recordData = Notification.Name("recordData")
    static let downloadData = Notification.Name("downloadData")
    static let fileDownloadProgressUpdate = Notification.Name("fileDownloadProgressUpdate")
    static let fileDownloadComplete = Notification.Name("fileDownloadComplete")
    static let saveFileLocally = Notification.Name("saveFileLocally")
    static let uploadFile = Notification.Name("uploadFile")
    static let fileStatus = Notification.Name("fileStatus")
    static let tryLogin = Notification.Name("tryLogin")
    static let deviceDisconnected = Notification.Name("deviceDisconnected")
    static let getWeather = Notification.Name("getWeather")
}


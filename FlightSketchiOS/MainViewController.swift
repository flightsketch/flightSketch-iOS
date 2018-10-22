//
//  ViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/16/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit


class MainViewController: UIViewController {

    @IBOutlet weak var menuTrailingConst: NSLayoutConstraint!
    @IBOutlet weak var currentAltitudeLabel: UILabel!
    @IBOutlet weak var maxAltitudeLabel: UILabel!
    @IBOutlet weak var sensorTempLabel: UILabel!
    
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
    
    
    var menuShowing = false
    //var connectionController: BLEConnectionModelController = BLEConnectionModelController()
    var deviceController: FSdeviceModelController = FSdeviceModelController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTrailingConst.constant = -200
        NotificationCenter.default.addObserver(self, selector: #selector(FSDeviceUpdate(_:)), name: .FSDeviceUpdate, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
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
    static let setZeroAlt = Notification.Name("setZeroAlt")
    static let sendBLEPacket = Notification.Name("sendBLEPacket")
    static let recordData = Notification.Name("recordData")
    static let downloadData = Notification.Name("downloadData")
    static let fileDownloadProgressUpdate = Notification.Name("fileDownloadProgressUpdate")
    static let fileDownloadComplete = Notification.Name("fileDownloadComplete")
    static let saveFileLocally = Notification.Name("saveFileLocally")
    static let uploadFile = Notification.Name("uploadFile")
}


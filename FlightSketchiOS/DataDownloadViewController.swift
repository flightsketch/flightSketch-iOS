//
//  DataDownloadViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/20/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import Alamofire

class DataDownloadViewController: UIViewController {

    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var fileNameTextField: UITextField!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var saveLocallyButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var weatherSwitch: UISwitch!
    @IBOutlet weak var weatherSwitchView: UIStackView!
    
    @IBAction func fileNameTextFieldPrimaryAction(_ sender: Any) {
        self.view.endEditing(true)
    }
    @IBAction func viewTapGesture(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    
    @IBAction func saveLocally(_ sender: Any) {
        let dataDict:[String: String] = ["fileName": fileNameTextField.text!]
        NotificationCenter.default.post(name: .saveFileLocally, object: nil, userInfo: dataDict)
    }
    @IBAction func uploadToWeb(_ sender: Any) {
        let dataDict:[String: Any] = ["fileName": fileNameTextField.text!, "title": titleTextField.text!, "description": descriptionTextField.text, "useWeather": weatherSwitch?.isOn ?? true]
        NotificationCenter.default.post(name: .uploadFile, object: nil, userInfo: dataDict)
    }
    
    @objc func updateFileStatus(_ notification: NSNotification) {
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            if let data = dict["status"] as? String{
                switch (data){
                case "saveComplete": do {
                    let alertController = UIAlertController(title: "Save Locally", message: "Complete!", preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    present(alertController, animated: true, completion: nil)
                    }
                case "saveFailed": do {
                    let alertController = UIAlertController(title: "Save Locally", message: "File did not save, error!", preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    present(alertController, animated: true, completion: nil)
                    }
                case "uploadComplete": do {
                    let alertController = UIAlertController(title: "Upload Data", message: "Complete!", preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    present(alertController, animated: true, completion: nil)
                    }
                case "uploadFailed": do {
                    let alertController = UIAlertController(title: "Upload Data", message: "File did not upload, check login!", preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    present(alertController, animated: true, completion: nil)
                    }
                default: saveLocallyButton.titleLabel?.text = "Unknown"
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateProgress(_:)), name: .fileDownloadProgressUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadComplete(_:)), name: .fileDownloadComplete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFileStatus(_:)), name: .fileStatus, object: nil)
        headerLabel.text = "Not Connected..."
        progressBar.progress = 0.0
        fileNameTextField.isHidden = true
        fileNameLabel.isHidden = true
        saveLocallyButton.isHidden = true
        uploadButton.isHidden = true
        titleLabel.isHidden = true
        titleTextField.isHidden = true
        descriptionLabel.isHidden = true
        descriptionTextField.isHidden = true
        weatherSwitchView.isHidden = true
        
        NotificationCenter.default.post(name: .getWeather, object: nil, userInfo: nil)
        
        
        
        
    }
    
    @objc func updateProgress(_ notification: NSNotification) {
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            //print("1")
            if let data = dict["progress"] as? Double{
                //print("2")
                progressBar.progress = Float(data)
                headerLabel.text = "Downloading Data..."
            }
        }
    }
    
    
    @objc func downloadComplete(_ notification: NSNotification) {
        let date = Date();
        // "Nov 2, 2016, 4:48 AM" <-- local time
        
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd__HH-mm-ss";
        let dateString = formatter.string(from: date);
        
        
        let file = "FltSk__" + dateString + ".csv"
        
        fileNameTextField.text = file
        titleTextField.text = ""
        descriptionTextField.text = ""
        fileNameLabel.isHidden = false
        headerLabel.text = "Download Complete"
        fileNameTextField.isHidden = false
        saveLocallyButton.isHidden = false
        uploadButton.isHidden = false
        titleLabel.isHidden = false
        titleTextField.isHidden = false
        descriptionLabel.isHidden = false
        descriptionTextField.isHidden = false
        weatherSwitchView.isHidden = false
    }
    
    
    
    
    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

//
//  AccountViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/23/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var userStatusLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self
        passwordTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(FSUserUpdate(_:)), name: .FSUserUpdate, object: nil)
        
        if (FSUser.sharedInstance.userName == "" || FSUser.sharedInstance.userName == nil){
            userStatusLabel.text = "Not Logged In"
        }
        else {
            userStatusLabel.text = "Logged in as " + FSUser.sharedInstance.userName!
        }
        

        // Do any additional setup after loading the view.
    }
    
    @objc func FSUserUpdate(_ notification: NSNotification) {
        if (FSUser.sharedInstance.userName == "" || FSUser.sharedInstance.userName == nil){
            userStatusLabel.text = "Not Logged In"
        }
        else {
            userStatusLabel.text = "Logged in as " + FSUser.sharedInstance.userName!
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("trigger")
        let nextTag = textField.tag + 1
        
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        if nextTag == 2 {
            tryLogin()
        }
        
        return true
    }
    
    func tryLogin(){
        let dataDict:[String: String] = ["username": userNameTextField.text!, "password": passwordTextField.text!]
        NotificationCenter.default.post(name: .tryLogin, object: nil, userInfo: dataDict)
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

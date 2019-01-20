//
//  FSUsersModelController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/23/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import Alamofire
import SwiftKeychainWrapper

class FSUsersModelController: NSObject {
    
    private var user = FSUser.sharedInstance
    
    override init(){
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(tryLogin(_:)), name: .tryLogin, object: nil)
    }
    
    func getKeychainToken(){
        
        let retrievedToken: String? = KeychainWrapper.standard.string(forKey: "FlightSketchToken")
        
        if (retrievedToken != nil){
            print("found token... ")
            print(retrievedToken!)
            print("\n")
            self.user.token = retrievedToken
            self.user.isLoggedIn = true
        }
    }
    
    @objc func tryLogin(_ notification: NSNotification) {
        print("try login")
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            print("1")
            let username = dict["username"] as? String
            let password = dict["password"] as? String
            
            let urlString = "https://flightsketch.com/api/api-token-auth/"
            
            Alamofire.request(urlString, method: .post, parameters: ["username" : username!, "password" : password!],encoding: JSONEncoding.default, headers: nil).responseJSON {
                response in
                switch response.result {
                case .success:
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        print(JSON)
                        self.user.token = (JSON["token"] as! String)
                        self.user.isLoggedIn = true
                        self.user.userName = username
                        
                        let saveSuccessful: Bool = KeychainWrapper.standard.set((JSON["token"] as! String), forKey: "FlightSketchToken")
                        NotificationCenter.default.post(name: .FSUserUpdate, object: nil, userInfo: nil)
                        print(saveSuccessful)
                    }
                    
                    break
                case .failure(let error):
                    
                    print(error)
                }
            }
            
        }
    }
    
    @objc func tryToken() {
        print("try token")
        
            
            let urlString = "https://flightsketch.com/api/verify-token/"
        
            let authToken = "Token " + self.user.token!
        
            let authHeader = [
                "Authorization": authToken
            ]
            print(authHeader)
            
            Alamofire.request(urlString, method: .get, headers: authHeader).responseJSON {
                response in
                switch response.result {
                case .success:
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        print(JSON)
                        self.user.userName = JSON["name"] as? String;
                        print(self.user.userName!)
                        NotificationCenter.default.post(name: .FSUserUpdate, object: nil, userInfo: nil)
                    }
                    
                    break
                case .failure(let error):
                    self.user.isLoggedIn = false
                    self.user.userName = ""
                    self.user.token = ""
                    
                    print(error)
                }
            }
            
        
    }
}

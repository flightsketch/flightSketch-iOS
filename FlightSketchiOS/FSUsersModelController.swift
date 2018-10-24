//
//  FSUsersModelController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/23/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import Alamofire

class FSUsersModelController: NSObject {
    
    private var user = FSUser.sharedInstance
    
    override init(){
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(tryLogin(_:)), name: .tryLogin, object: nil)
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
                        self.user.token = JSON["token"] as! String
                        self.user.isLoggedIn = true
                        self.user.userName = username
                    }
                    
                    break
                case .failure(let error):
                    
                    print(error)
                }
            }
            
        }
    }
}

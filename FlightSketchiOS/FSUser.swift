//
//  FSUser.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/23/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class FSUser: NSObject {
    
    static var sharedInstance = FSUser()
    
    var token: String?
    var isLoggedIn: Bool = false
    var userName: String?
    
    
    private override init() {
        super.init()
    }
    
    

}

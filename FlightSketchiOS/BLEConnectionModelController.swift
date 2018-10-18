//
//  BLEConnection.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class BLEConnectionModelController: NSObject {
    private var connection: BLEConnection
    
    override init() {
        self.connection = BLEConnection()
        print("hello world")
    }
    
    func sayHello(){
        print("hello...")
    }
}


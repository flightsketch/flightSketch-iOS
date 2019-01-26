//
//  FSDevice.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/20/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class FSDeviceModel: NSObject {
    
    var currentAltitude: Double?
    var maxAltitude: Double?
    var temp: Double?
    var battVoltage: Double?
    var isRecording: Bool = false
    var isArmedForLaunch: Bool = false
    
    override init(){
        super.init()
    }

}

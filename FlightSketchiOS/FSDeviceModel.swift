//
//  FSDevice.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/20/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import CoreLocation

class FSDeviceModel: NSObject {
    
    var currentAltitude: Double?
    var maxAltitude: Double?
    var temp: Double?
    var battVoltage: Double?
    var isRecording: Bool = false
    var isArmedForLaunch: Bool = false
    
    var avgWind: Double?
    var windGust: Double?
    var windDir: Double?
    var currentTemp: Double?
    var cloudCover: Double?
    var humidity: Double?
    
    var apogee: Double?
    var maxSpeed: Double?
    var avgDescentRate: Double?
    var timeToBurnout: Double?
    var timeToApogee: Double?
    var totalTime: Double?
    
    var location: CLLocationCoordinate2D?
    
    override init(){
        super.init()
        
    }

}

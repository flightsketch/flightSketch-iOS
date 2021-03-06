//
//  BLEConnection.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEConnection : NSObject{
    
    static var sharedInstance = BLEConnection()
    
    var centralManager: CBCentralManager = CBCentralManager()
    var deviceList = [(peripheral: CBPeripheral,  lastUpdate: Date?, RSSI: NSNumber)]()
    var isConnected: Bool = false
    var connectedDevice:CBPeripheral?
    var lastKnownDevice:CBPeripheral?

    var controller: BLEConnectionModelController?
    var txCharacteristic: CBCharacteristic?
    

    private override init() {
        super.init()
    }
    
    
}

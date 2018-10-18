//
//  BLEConnection.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEConnectionModelController: NSObject, CBCentralManagerDelegate {
    
    
    private var connection = BLEConnection.sharedInstance
    
    
    override init() {
        super.init()
        configConnection()
        print("hello world")
    }
    
    
    func configConnection() {
        connection.centralManager.delegate = self
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .unknown:
            NSLog("unknown")
        case .resetting:
            NSLog("resetting")
        case .unsupported:
            NSLog("unsupported")
        case .unauthorized:
            NSLog("unauthorized")
        case .poweredOff:
            NSLog("powered off")
        case .poweredOn:
            NSLog("powered on")
            
        connection.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let i = connection.deviceList.index(where: ({ $0.peripheral === peripheral })) {
            connection.deviceList[i].RSSI = RSSI
            connection.deviceList[i].lastUpdate = Date()
            //devTable.reloadData()
        }
        else {
            if (peripheral.name?.range(of:"FltSk-") != nil) {
                connection.deviceList.append((peripheral, Date(), RSSI))
                connection.deviceList.sort { ($0.RSSI.floatValue ) > ($1.RSSI.floatValue ) }// optionally sort array to signal strength
            }
            NotificationCenter.default.post(name: .deviceListChanged, object: self)
            print(connection.deviceList)
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //altPeripheral.discoverServices([service_ID])
    }
    
    
}

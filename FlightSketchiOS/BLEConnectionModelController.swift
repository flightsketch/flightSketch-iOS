//
//  BLEConnection.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEConnectionModelController: NSObject {
    private var connection: BLEConnection
    
    override init() {
        self.connection = BLEConnection.sharedInstance
        print("hello world")
    }
    
    func sayHello(){
        print("hello...")
    }
}




extension BLEConnection: CBCentralManagerDelegate {
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
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let i = deviceList.index(where: ({ $0.peripheral === peripheral })) {
            deviceList[i].RSSI = RSSI
            deviceList[i].lastUpdate = Date()
            //devTable.reloadData()
        }
        else {
            if (peripheral.name?.range(of:"FltSk-") != nil) {
                deviceList.append((peripheral, Date(), RSSI))
                deviceList.sort { ($0.RSSI.floatValue ) > ($1.RSSI.floatValue ) }// optionally sort array to signal strength
            }
            //devTable.reloadData()
            print(deviceList)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //altPeripheral.discoverServices([service_ID])
    }
    
}

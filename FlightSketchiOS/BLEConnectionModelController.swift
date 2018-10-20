//
//  BLEConnection.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEConnectionModelController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
    private var connection = BLEConnection.sharedInstance
    var deviceCleanupTimer: Timer!
    
    
    override init() {
        super.init()
        configConnection()
        deviceCleanupTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(cleanupDeviceList), userInfo: nil, repeats: true)
    }
    
    @objc func cleanupDeviceList() {
        for i in (0..<connection.deviceList.count).reversed() {
            if connection.deviceList[i].lastUpdate!.timeIntervalSinceNow < -3.0 { // 2s max inactivity
                if (connection.deviceList[i].peripheral != BLEConnection.sharedInstance.connectedDevice){
                    connection.deviceList.remove(at: i)
                }
                NotificationCenter.default.post(name: .deviceListChanged, object: self)
            }
        }
    }
    
    
    func configConnection() {
        connection.centralManager.delegate = self
        connection.controller = self
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
            //print(connection.deviceList)
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connect")
        BLEConnection.sharedInstance.connectedDevice = peripheral
        peripheral.delegate = self
        BLEConnection.sharedInstance.isConnected = true
        NotificationCenter.default.post(name: .deviceListChanged, object: self)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnect")
        BLEConnection.sharedInstance.connectedDevice = nil
        BLEConnection.sharedInstance.isConnected = false
    }
    
    
}

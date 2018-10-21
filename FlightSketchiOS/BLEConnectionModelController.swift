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
    let service_ID = CBUUID(string: "49535343-fe7d-4ae5-8fa9-9fafd205e455")
    let characteristic_ID = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    
    
    override init() {
        super.init()
        configConnection()
        deviceCleanupTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(cleanupDeviceList), userInfo: nil, repeats: true)
        NotificationCenter.default.removeObserver(self, name: .sendBLEPacket, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sendBLEPacket(_:)), name: .sendBLEPacket, object: nil)
    }
    
    @objc func sendBLEPacket(_ notification: NSNotification) {
        print("send packet")
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            print("1")
            if let data = dict["data"] as? [UInt8]{
                print("2")
                //print("dataRx:" + data.base64EncodedString())
                connection.connectedDevice!.writeValue(Data(bytes: data), for: connection.txCharacteristic!, type:CBCharacteristicWriteType.withoutResponse)
            }
        }
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
        peripheral.discoverServices([service_ID])
        NotificationCenter.default.post(name: .deviceListChanged, object: self)
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnect")
        BLEConnection.sharedInstance.connectedDevice = nil
        BLEConnection.sharedInstance.isConnected = false
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        //print(RSSI)
        //lbRSSI.text = RSSI.stringValue
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics([characteristic_ID], for: service)
            print("service found...")
            print(service.uuid)
            print("end service...")
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.read) {
                //print("\(characteristic.uuid): properties contains .read")
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.writeWithoutResponse) {
                print("\(characteristic.uuid): properties contains .writeWithoutResponse")
                BLEConnection.sharedInstance.txCharacteristic = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        switch characteristic.uuid {
            
        default:
            //print("Unhandled Characteristic UUID: \(characteristic.uuid)")
            readData(from: characteristic)
        }
    }
    
    private func readData(from characteristic: CBCharacteristic) {
        //altPeripheral.readRSSI()
        //parseData(byte: characteristic.value!)
        //print(characteristic.value)
        let dataDict:[String: Data] = ["data": (characteristic.value)!]
        NotificationCenter.default.post(name: .BLEDataRx, object: nil, userInfo: dataDict)
    }
    
    
    
    
    
    
}

//
//  FSdevice.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class FSdeviceModelController: NSObject {
    
    @objc func BLEDataRx(_ notification: NSNotification) {
        print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            if let data = dict["data"] as? Data{
                print("dataRx:" + data.base64EncodedString())
                parseData(byte: data)
            }
        }
    }
    
    
    override init(){
        print("sub")
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(BLEDataRx(_:)), name: .BLEDataRx, object: nil)
    }
    
    
    func parseData(byte: Data) {
        print("rx data")
        print(byte.count)
        let byteArray = [UInt8](byte)
        for byte in byteArray {
            //parseByte(byte: byte)
            print(byte)
        }
    }

}

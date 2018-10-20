//
//  FSdevice.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class FSdeviceModelController: NSObject {
    
    
    var inHead = false
    var inData = false
    var startByte: UInt8 = 0xF5
    var headCount: UInt8 = 0
    var dataCount = 0
    var packetType: UInt8 = 0
    var dataLength: UInt8 = 0
    var checksum: UInt8 = 0
    var dataArray: [UInt8] = []
    var downloadFile: [Double] = []
    var fileCounter: Int = 0
    var fileURL: URL = URL(string: "https://www.apple.com")!
    var FSDevice: FSDeviceModel = FSDeviceModel()
    
    @objc func BLEDataRx(_ notification: NSNotification) {
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            if let data = dict["data"] as? Data{
                //print("dataRx:" + data.base64EncodedString())
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
        //print("rx data")
        //print(byte.count)
        let byteArray = [UInt8](byte)
        for byte in byteArray {
            parseByte(byte: byte)
            //print(byte)
        }
    }
    
    
    func parseByte(byte: UInt8) {
        //print("byte rx:")
        //print(byte)
        if (!inHead || !inData){ //Not in header or data, waiting for start of frame
            if (byte == 0xF5){ //Start of packet
                //print("start of packet...................")
                inHead = true
                headCount = 0
                return
            }
        }
        if (inHead && headCount<3){ //Reading header bytes
            headCount = headCount + 1
            switch (headCount){
            case 1: packetType = byte
            case 2: dataLength = byte
            case 3: do {
                checksum = (self.startByte &+ self.packetType &+ self.dataLength)
                //print("Head checksum = ")
                //print(checksum)
                if (byte != checksum){
                    inHead = false
                    inData = false
                    print("Head Checksum failed...............")
                    print(packetType)
                    return
                }
                else { //Checksum valid, start reading data packet
                    if (dataLength > 0){
                        inData = true
                        dataCount = 0
                        dataArray = Array(repeating: 0, count: Int(dataLength))
                        return
                    }
                    else {
                        inHead = false //reset flags to wait for new frame
                        inData = false
                        switch (packetType){
                        case 5: parsePacket_type5()
                        default: print("default")
                        }
                    }
                }
                }
            default: inHead = false
            }
        }
        if (inData){ //In data packet
            if (dataCount<(dataLength)){ //Read data to array
                dataArray[dataCount] = byte
                dataCount = dataCount + 1
                return
            }
            
            if (dataCount == dataLength){ //Last byte = checksum
                if (byte != doChecksum(dataArray: dataArray)){
                    inHead = false
                    inData = false
                    print("Data Checksum failed...............")
                    return
                }
                else { //Checksum valid, start reading data packet
                    //print(dataArray)
                    inHead = false //reset flags to wait for new frame
                    inData = false
                    switch (packetType){
                    case 1: parsePacket_type1()
                    case 2: parsePacket_type2()
                    case 3: parsePacket_type3()
                    case 4: parsePacket_type4()
                    case 6: parsePacket_type6()
                    default: print("default")
                    }
                    return
                }
            }
        }
    }
    
    func doChecksum(dataArray: [UInt8]) -> UInt8 {
        checksum = 0
        for byte in dataArray {
            checksum = checksum &+ byte
        }
        return checksum
    }
    
    func parsePacket_type1() {
        
        var temp: Int = 0
        var alt: Int = 0
        var maxAlt: Int = 0
        for i in 0..<4 {
            temp = temp + Int(dataArray[i]) << (8*i)
        }
        for i in 4..<8 {
            alt = alt + Int(dataArray[i]) << (8*(i-4))
        }
        for i in 8..<12 {
            maxAlt = maxAlt + Int(dataArray[i]) << (8*(i-8))
        }
        //tempLabel.text = String((Double(temp)/100.0)*(9.0/5.0)+32.0)
        //altLabel.text = String(format: "%.1f", Double(alt)/10.0 - 1000.0)
        //maxAltLabel.text = String(format: "%.1f", Double(maxAlt)/10.0 - 1000.0)
        //print("temp: " + String(format: "%.1f", (Double(temp)/100.0)*(9.0/5.0)+32.0))
        //print("alt: " + String(format: "%.1f", Double(alt)/10.0 - 1000.0))
        
        FSDevice.currentAltitude = Double(alt)/10.0 - 1000.0
        FSDevice.maxAltitude = Double(maxAlt)/10.0 - 1000.0
        FSDevice.temp = (Double(temp)/100.0)*(9.0/5.0)+32.0
        
        let dataDict:[String: FSDeviceModel] = ["data": FSDevice]
        NotificationCenter.default.post(name: .FSDeviceUpdate, object: nil, userInfo: dataDict)
        
        temp = 0
        alt = 0
    }
    
    func parsePacket_type2() {
        var batt: Int = 0
        for i in 0..<2 {
            batt = batt + Int(dataArray[i]) << (8*i)
        }
        
        FSDevice.battVoltage = (3.0*3.3*Double(batt)/4096.0)
        //battVbt.text = String(format: "%.2f", battV)
        
    }
    
    func parsePacket_type3() {
        var fileLength: Int = 0
        for i in 0..<4 {
            fileLength = fileLength + Int(dataArray[i]) << (8*i)
        }
        print("File Length =  \(fileLength)")
        //downloadFile = Array(repeating: 0, count: fileLength/4)
        //fileCounter = 0
    }
    
    func parsePacket_type4() {
        var alt: Int = 0
        
        for i in 0..<4 {
            alt = alt + Int(dataArray[i]) << (8*i)
        }
        
        downloadFile[fileCounter] = Double(alt)/10.0 - 1000.0
        fileCounter = fileCounter + 1
        //print("rx packet3...")
        //print(Double(alt)/10.0 - 1000.0)
        
        
    }
    
    func parsePacket_type5() {
        var line = "FlightSketch Header v1.0"
        line = line + "\n"
        line = line + "Altitude (ft)\n"
        print("End of file...")
        //print(downloadFile)
        
        let date = Date();
        // "Nov 2, 2016, 4:48 AM" <-- local time
        
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd__HH-mm-ss";
        let dateString = formatter.string(from: date);
        
        
        let file = "FlightSketch__" + dateString + ".csv"
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        fileURL = (dir?.appendingPathComponent(file))!
        do {
            try line.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {
            print("error...")
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            
            for i in 0..<fileCounter{
                line = String(format: "%.1f", downloadFile[i])
                line = line + "\n"
                
                
                fileHandle.seekToEndOfFile()
                fileHandle.write(line.data(using: .utf8)!)
                
                
            }
            fileHandle.closeFile()
        } catch {
            print("error...")
        }
        
        
    }
    
    func parsePacket_type6() {
        print("packet6")
        print(dataArray)
        
        
    }

}

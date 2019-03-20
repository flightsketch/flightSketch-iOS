//
//  FSdevice.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import Alamofire

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
    
    @objc func saveFileLocally(_ notification: NSNotification) {
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            if let data = dict["fileName"] as? String{
                saveFile(file: data)
            }
        }
    }
    
    @objc func uploadFile(_ notification: NSNotification) {
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            let data = dict["fileName"]
            uploadFile(file: dict["fileName"] as! String, title: dict["title"] as! String, description: dict["description"] as! String)
        }
    }
    
    @objc func setZeroAlt(_ notification: NSNotification) {
        print("device rx signal")
        
        let packet: [UInt8] = [0xf5, 0xf1, 0x00, 0xE6]
        let dataDict:[String: [UInt8]] = ["data": packet]
        NotificationCenter.default.post(name: .sendBLEPacket, object: nil, userInfo: dataDict)
    }
    
    @objc func recordData(_ notification: NSNotification) {
        print("device rx signal")
        let packet: [UInt8] = [0xf5, 0xf2, 0x00, 0xE7]
        let dataDict:[String: [UInt8]] = ["data": packet]
        NotificationCenter.default.post(name: .sendBLEPacket, object: nil, userInfo: dataDict)
    }
    
    @objc func downloadData(_ notification: NSNotification) {
        print("device rx signal")
        let packet: [UInt8] = [0xf5, 0xf4, 0x00, 0xE9]
        let dataDict:[String: [UInt8]] = ["data": packet]
        NotificationCenter.default.post(name: .sendBLEPacket, object: nil, userInfo: dataDict)
    }
    
    @objc func deviceDisconnected(_ notification: NSNotification) {
        print("device disconnected signal")
        FSDevice.currentAltitude = nil
        FSDevice.battVoltage = nil
        FSDevice.maxAltitude = nil
        FSDevice.temp = nil
        FSDevice.isArmedForLaunch = false
        FSDevice.isRecording = false
        
        let dataDict:[String: FSDeviceModel] = ["data": FSDevice]
        NotificationCenter.default.post(name: .FSDeviceUpdate, object: nil, userInfo: dataDict)
    }
    
    
    override init(){
        print("sub")
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(BLEDataRx(_:)), name: .BLEDataRx, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setZeroAlt(_:)), name: .setZeroAlt, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(recordData(_:)), name: .recordData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadData(_:)), name: .downloadData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveFileLocally(_:)), name: .saveFileLocally, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadFile(_:)), name: .uploadFile, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDisconnected(_:)), name: .deviceDisconnected, object: nil)
    }
    
    
    func parseData(byte: Data) {
        //print("rx data")
        //print(byte.count)
        let byteArray = [UInt8](byte)
        //print("Array...")
        //print(byteArray)
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
        var tempF: Float = 0;
        memcpy(&tempF, Array(dataArray[0..<4]), 4)
        var altF: Float = 0;
        memcpy(&altF, Array(dataArray[4..<8]), 4)
        var maxF: Float = 0;
        memcpy(&maxF, Array(dataArray[8..<12]), 4)
        
        //print(Array(dataArray[0..<4]))
        
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
        
        //FSDevice.currentAltitude = Double(alt)/10.0 - 1000.0
        FSDevice.currentAltitude = Double(altF)
        //FSDevice.maxAltitude = Double(maxAlt)/10.0 - 1000.0
        FSDevice.maxAltitude = Double(maxF)
        //FSDevice.temp = (Double(temp)/100.0)*(9.0/5.0)+32.0
        FSDevice.temp = (Double(tempF))*(9.0/5.0)+32.0
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
        FSDevice.battVoltage = (Double(batt)/1000.0)
        //battVbt.text = String(format: "%.2f", battV)
        
    }
    
    func parsePacket_type3() {
        var fileLength: Int = 0
        for i in 0..<4 {
            fileLength = fileLength + Int(dataArray[i]) << (8*i)
        }
        print("File Length =  \(fileLength)")
        downloadFile = Array(repeating: 0, count: fileLength/4)
        fileCounter = 0
    }
    
    func parsePacket_type4() {
        var alt: Int = 0
        
        for i in 0..<4 {
            alt = alt + Int(dataArray[i]) << (8*i)
        }
        
        var altF: Float = 0;
        memcpy(&altF, Array(dataArray[0..<4]), 4)
        
        print("Data... ")
        print(altF)
        print("\n")
        downloadFile[fileCounter] = Double(altF)
        fileCounter = fileCounter + 1
        if (fileCounter % 10 == 0){
            let progress = Double(fileCounter)/Double(downloadFile.count)
            let dataDict:[String: Double] = ["progress": progress]
            NotificationCenter.default.post(name: .fileDownloadProgressUpdate, object: nil, userInfo: dataDict)
        }
        //print("rx packet3...")
        //print(Double(alt)/10.0 - 1000.0)
        
    }
    
    
    func parsePacket_type5() {
        print("End of file...")
        
        let dataDict:[String: Double] = ["progress": 1.0]
        NotificationCenter.default.post(name: .fileDownloadProgressUpdate, object: nil, userInfo: dataDict)
        
        NotificationCenter.default.post(name: .fileDownloadComplete, object: self)
    }
    
    
    func parsePacket_type6() {
        print("packet6")
        print(dataArray)
        let recordingMask: UInt8 = 0b00000010
        let armedForLaunchMask: UInt8 = 0b00000001
        if ((dataArray[0] & recordingMask) == recordingMask){
            FSDevice.isRecording = true
        }
        else {
            FSDevice.isRecording = false
        }
        if ((dataArray[0] & armedForLaunchMask) == armedForLaunchMask){
            FSDevice.isArmedForLaunch = true
        }
        else {
            FSDevice.isArmedForLaunch = false
        }
        
        let dataDict:[String: FSDeviceModel] = ["data": FSDevice]
        NotificationCenter.default.post(name: .FSDeviceUpdate, object: nil, userInfo: dataDict)
    }
    
    
    func saveFile(file: String){
        var line = "time, pressure, altitude, velocity\n"
        

        
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
            
            for i in 0..<fileCounter/4{
                line = String(format: "%.3f", downloadFile[4*i])
                line = line + ","
                line = line + String(format: "%.3f", downloadFile[4*i+1])
                line = line + ","
                line = line + String(format: "%.3f", downloadFile[4*i+2])
                line = line + ","
                line = line + String(format: "%.3f", downloadFile[4*i+3])
                line = line + "\n"
                
                
                fileHandle.seekToEndOfFile()
                fileHandle.write(line.data(using: .utf8)!)
                
                
            }
            fileHandle.closeFile()
            let dataDict:[String: String] = ["status": "saveComplete"]
            NotificationCenter.default.post(name: .fileStatus, object: nil, userInfo: dataDict)
        } catch {
            print("error...")
            let dataDict:[String: String] = ["status": "saveFailed"]
            NotificationCenter.default.post(name: .fileStatus, object: nil, userInfo: dataDict)
        }
    }
    
    
    func uploadFile(file: String, title: String, description: String){
        let REST_UPLOAD_API_URL = "https://flightsketch.com/api/flights/"
        let authToken = "Token " + FSUser.sharedInstance.token!
        
        let headers = [
            "Authorization": authToken
        ]
        
        let parameters: Parameters = ["title": title,
                                      "description": description]
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                for (key, value) in parameters {
                    if value is String || value is Int {
                        multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
                    }
                }
                var dataString: String = "time,pressure,altitude,velocity\n"
                var line: String
                
                for i in 0..<self.fileCounter/4{
                    line = String(format: "%.3f", self.downloadFile[4*i])
                    line = line + ","
                    line = line + String(format: "%.5f", self.downloadFile[4*i+1])
                    line = line + ","
                    line = line + String(format: "%.3f", self.downloadFile[4*i+2])
                    line = line + ","
                    line = line + String(format: "%.3f", self.downloadFile[4*i+3])
                    line = line + "\n"
                    dataString = dataString + line
                }
                
                let data = dataString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                //  multipartFormData.append(self.fileURL, withName: "photo")
                //data.append(contentsOf: bytes)
                multipartFormData.append(data, withName: "logFile", fileName: file, mimeType: "application/octet-stream")
                
                
        },
            to: REST_UPLOAD_API_URL,
            headers: headers,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                        let dataDict:[String: String] = ["status": "uploadComplete"]
                        NotificationCenter.default.post(name: .fileStatus, object: nil, userInfo: dataDict)
                        
                    }
                case .failure(let encodingError):
                    print("encoding Error : \(encodingError)")
                    let dataDict:[String: String] = ["status": "uploadFailed"]
                    NotificationCenter.default.post(name: .fileStatus, object: nil, userInfo: dataDict)
                }
        })
    }

}

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
            uploadFile(file: dict["fileName"] as! String, title: dict["title"] as! String, description: dict["description"] as! String, useWeather: dict["useWeather"] as! Bool)
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
    
    @objc func getWeather(_ notification: NSNotification) {
        print("get weather in fsdevice")
        let urlString = "https://flightsketch.com/weather/"
        
        let parameters: Parameters = ["lat" : self.FSDevice.location?.latitude as Any, "lon" : self.FSDevice.location?.longitude as Any]
        
        Alamofire.request(urlString, method: .get, parameters: parameters,encoding: URLEncoding.default, headers: nil).responseJSON {
            response in
            switch response.result {
            case .success:
                print(response)
                if let result = response.result.value {
                    let JSON = result as! NSDictionary
                    print(JSON)
                    if (JSON["avg_wind"] != nil){
                        self.FSDevice.avgWind = (JSON["avg_wind"] as! Double)
                    }
                    if (JSON["wind_dir"] != nil){
                        self.FSDevice.windDir = (JSON["wind_dir"] as! Double)
                    }
                    if (JSON["wind_gust"] != nil){
                        self.FSDevice.windGust = (JSON["wind_gust"] as! Double)
                    }
                    if (JSON["temp"] != nil){
                        self.FSDevice.currentTemp = (JSON["temp"] as! Double)
                    }
                    if (JSON["humidity"] != nil){
                        self.FSDevice.humidity = (JSON["humidity"] as! Double)
                    }
                    if (JSON["cloud_cover"] != nil){
                        self.FSDevice.cloudCover = (JSON["cloud_cover"] as! Double)
                    }
                }
                
                break
            case .failure(let error):
                print(response)
                print(error)
            }
        }
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(getWeather(_:)), name: .getWeather, object: nil)
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
        if (fileCounter > 16){
            processDataFile()
        }
    }
    
    func processDataFile() {
        
        let npts = downloadFile.count/4
        var time: Double = 0
        var press: Double = 0
        var alt: Double = 0
        var spd: Double = 0
        var apogee: Double = -999.999
        var launch: Bool = false
        var burnout: Bool = false
        
        var rawAlt: Double = 0
        
        var y: [Double] = Array(repeating: 0, count: npts)
        var x: [Double] = Array(repeating: 0, count: npts)
        
        var x2: [Double] = Array(repeating: 0, count: npts)
        var x3: [Double] = Array(repeating: 0, count: npts)
        var x4: [Double] = Array(repeating: 0, count: npts)
        
        var yx: [Double] = Array(repeating: 0, count: npts)
        var yx2: [Double] = Array(repeating: 0, count: npts)
        
        var sumX: Double = 0.0
        var sumY: Double = 0.0
        
        var sumX2: Double = 0.0
        var sumX3: Double = 0.0
        var sumX4: Double = 0.0
        
        var sumYX: Double = 0.0
        var sumYX2: Double = 0.0
        
        var C1: Double = 0.0
        var C2: Double = 0.0
        
        var factor: Double = 0.0
        var accel: Double = 0.0
        
        var dim: Int = 10
        var n: Double = 21.0
        
        var timeOffset: Double = 0.0
        
        var accel_hist: [Double] = Array(repeating: 0, count: npts)
        
        
        
        for i in 0..<npts {
            time = downloadFile[4*i+0]
            press = downloadFile[4*i+1]
            alt = downloadFile[4*i+2]
            spd = downloadFile[4*i+3]
            
            rawAlt = press/101.325
            rawAlt = pow(rawAlt,0.190284)
            rawAlt = 1.0 - rawAlt
            rawAlt = rawAlt * 145366.45
            
            x[i] = time
            y[i] = rawAlt
            
            x2[i] = pow(time,2.0)
            x3[i] = pow(time,3.0)
            x4[i] = pow(time,4.0)
            
            yx[i] = time*rawAlt
            yx2[i] = x2[i]*rawAlt
            
            if (spd > 30.0 && alt > 15.0){
                launch = true
            }
            
            if (alt > apogee){
                apogee = alt
                FSDevice.apogee = alt
                FSDevice.timeToApogee = time
            }
        }
        
        launch = false
        FSDevice.maxSpeed = -999.999
        
        for i in 0..<npts {
            if (i<11 || i>(npts-51)){
                downloadFile[4*i+3] = 0
            }
            else {
                sumX = x[i-dim...i+dim].reduce(0.0, +)
                sumY = y[i-dim...i+dim].reduce(0.0, +)
                
                sumX2 = x2[i-dim...i+dim].reduce(0.0, +)
                sumX3 = x3[i-dim...i+dim].reduce(0.0, +)
                sumX4 = x4[i-dim...i+dim].reduce(0.0, +)
                
                sumYX = yx[i-dim...i+dim].reduce(0.0, +)
                sumYX2 = yx2[i-dim...i+dim].reduce(0.0, +)
                
                factor = 1/(-pow(sumX2,3)+sumX4*n*sumX2+2.0*sumX3*sumX*sumX2-sumX4*pow(sumX,2)-pow(sumX3,2)*n)
                C1 = factor*(sumYX*(sumX2*sumX-sumX3*n)+sumY*(sumX3*sumX-pow(sumX2,2))+sumYX2*(sumX2*n-pow(sumX,2)))
                C2 = factor*(sumYX*(sumX4*n-pow(sumX2,2))+sumY*(sumX2*sumX3-sumX4*sumX)+sumYX2*(sumX2*sumX-sumX3*n))
                
                spd = 2*C1*x[i] + C2
                accel = 2*C1
                accel_hist[i] = accel
                
                downloadFile[4*i+3] = spd
                
                if (spd > 30.0 && !launch){
                    launch = true
                    timeOffset = x[i] - 0.100
                }
                
                
                
                if (spd > FSDevice.maxSpeed!){
                    FSDevice.maxSpeed = spd
                }
                
                if (!burnout && launch && (accel < -32.2) && (accel_hist[i-10] < -32.2)){
                    FSDevice.timeToBurnout = x[i] - 0.200
                    burnout = true
                }
            }
            if (burnout && dim<50){
                dim = dim + 1
                n = n+2.0
            }
        }
        
        for i in 0..<npts {
            downloadFile[4*i+0] = downloadFile[4*i+0] - timeOffset
        }
        
        FSDevice.totalTime = time - timeOffset
        FSDevice.timeToBurnout = FSDevice.timeToBurnout! - timeOffset
        FSDevice.timeToApogee = FSDevice.timeToApogee! - timeOffset
        FSDevice.avgDescentRate = apogee/(FSDevice.totalTime! - FSDevice.timeToApogee!)
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
    
    
    func uploadFile(file: String, title: String, description: String, useWeather: Bool){
        let REST_UPLOAD_API_URL = "https://flightsketch.com/api/rocketflights/"
        let authToken = "Token " + FSUser.sharedInstance.token!
        
        let headers = [
            "Authorization": authToken
        ]
        
        var parameters: Parameters = ["title": title,
                                      "description": description,
                                      "apogee": String(format:"%.3f", self.FSDevice.apogee ?? 0.0),
                                      "max_vertical_velocity": String(format:"%.3f", self.FSDevice.maxSpeed ?? 0.0),
                                      "avg_descent_rate": String(format:"%.3f", self.FSDevice.avgDescentRate ?? 0.0),
                                      "time_to_burnout": String(format:"%.3f", self.FSDevice.timeToBurnout ?? 0.0),
                                      "time_to_apogee": String(format:"%.3f", self.FSDevice.timeToApogee ?? 0.0),
                                      "time_to_landing": String(format:"%.3f", self.FSDevice.totalTime ?? 0.0)]
        
        if (useWeather){
            print("using weather")
            parameters = ["title": title,
                          "description": description,
                          "avg_wind": String(format:"%.3f", self.FSDevice.avgWind ?? 0.0),
                          "wind_gust": String(format:"%.3f", self.FSDevice.windGust ?? 0.0),
                          "wind_dir": String(format:"%.3f", self.FSDevice.windDir ?? 0.0),
                          "temp": String(format:"%.3f", self.FSDevice.currentTemp ?? 0.0),
                          "humidity": String(format:"%.3f", self.FSDevice.humidity ?? 0.0),
                          "cloud_cover": String(format:"%.3f", self.FSDevice.cloudCover ?? 0.0),
                          "apogee": String(format:"%.3f", self.FSDevice.apogee ?? 0.0),
                          "max_vertical_velocity": String(format:"%.3f", self.FSDevice.maxSpeed ?? 0.0),
                          "avg_descent_rate": String(format:"%.3f", self.FSDevice.avgDescentRate ?? 0.0),
                          "time_to_burnout": String(format:"%.3f", self.FSDevice.timeToBurnout ?? 0.0),
                          "time_to_apogee": String(format:"%.3f", self.FSDevice.timeToApogee ?? 0.0),
                          "time_to_landing": String(format:"%.3f", self.FSDevice.totalTime ?? 0.0)]
        }
        
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

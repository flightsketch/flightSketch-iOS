//
//  ConnectionsViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import Foundation

class ConnectionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var deviceTable: UITableView!
    @IBOutlet weak var deviceTableCellText: UILabel!


    var connectionController: BLEConnectionModelController = BLEConnectionModelController()


    override func viewDidLoad() {
        super.viewDidLoad()
        //print("nc create")
        NotificationCenter.default.post(name: .tn, object: self)
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(deviceListChanged), name: .deviceListChanged, object: nil)
        deviceTable.dataSource = self
        deviceTable.delegate = self
    }


    @objc func deviceListChanged(){
        //print("deviceListChanged...")
        deviceTable.reloadData()
    }


    //func subscribe(for container: BLEConnectionModelController) {
    //    NotificationCenter.default.addObserver(self, selector: #selector(deviceListChanged), name: .tn, object: nil)
    //}


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLEConnection.sharedInstance.deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("buildingCells...")
        let cell = deviceTable.dequeueReusableCell(withIdentifier: "deviceTableCell") as! DeviceTableViewCell
        var text = "name"
        if (BLEConnection.sharedInstance.deviceList[indexPath.row].peripheral.name != nil) {
            cell.NameLabel.text = BLEConnection.sharedInstance.deviceList[indexPath.row].peripheral.name!
            text = "RSSI:  "
            text = text + BLEConnection.sharedInstance.deviceList[indexPath.row].RSSI.stringValue
            cell.RSSILabel.text = text
            cell.ConnectedLabel.isHidden = !BLEConnection.sharedInstance.isConnected
        }
        else {
            text = "no name"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //print("selected...")
        if(BLEConnection.sharedInstance.connectedDevice != nil){  //disconnect from existing device
            BLEConnection.sharedInstance.centralManager.cancelPeripheralConnection(BLEConnection.sharedInstance.connectedDevice!)
        }
        let peripheral = BLEConnection.sharedInstance.deviceList[indexPath.row].peripheral
        
        BLEConnection.sharedInstance.centralManager.connect(peripheral, options: nil)
        
        deviceTable.reloadData()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

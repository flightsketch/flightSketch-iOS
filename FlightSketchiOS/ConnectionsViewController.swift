//
//  ConnectionsViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/17/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit
import Foundation

class ConnectionsViewController: UIViewController {

    var connectionController: BLEConnectionModelController = BLEConnectionModelController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("nc create")
        NotificationCenter.default.post(name: .tn, object: self)
        // Do any additional setup after loading the view.
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

//
//  DeviceTableViewCell.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/19/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class DeviceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var NameLabel: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var ConnectedLabel: UILabel!
    
    var deviceName = "name"
    var RSSI = -42
    

    override func awakeFromNib() {
        super.awakeFromNib()
        self.ConnectedLabel.isHidden = true
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

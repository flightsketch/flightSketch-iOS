//
//  ViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/16/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit


class MainViewController: UIViewController {

    @IBOutlet weak var menuTrailingConst: NSLayoutConstraint!
    
    
    
    var menuShowing = false
    var connectionController: BLEConnectionModelController = BLEConnectionModelController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTrailingConst.constant = -200
        NotificationCenter.default.addObserver(self, selector: #selector(getDataUpdate), name: .tn, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @objc private func getDataUpdate() {
        print("Notification rx by MainViewController")
    }
    
    func subscribe(for container: ConnectionsViewController) {
        NotificationCenter.default.addObserver(self, selector: #selector(getDataUpdate), name: .tn, object: nil)
    }
    
    
    @IBAction func toggleMenu(_ sender: Any) {
        if menuShowing {
            menuTrailingConst.constant = -200
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            })
        }
        else {
            menuTrailingConst.constant = 0
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
                })
        }
        
        menuShowing = !menuShowing
        
    }
    
}

extension Notification.Name {
    static let tn = Notification.Name("tn")
    static let argentina = Notification.Name("argentina")
}


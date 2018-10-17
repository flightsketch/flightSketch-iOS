//
//  ViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/16/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var menuTrailingConst: NSLayoutConstraint!
    
    
    var menuShowing = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTrailingConst.constant = -200
        // Do any additional setup after loading the view, typically from a nib.
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


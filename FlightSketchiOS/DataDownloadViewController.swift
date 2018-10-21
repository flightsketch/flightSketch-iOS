//
//  DataDownloadViewController.swift
//  FlightSketchiOS
//
//  Created by Russell P. Parrish on 10/20/18.
//  Copyright © 2018 Russell P. Parrish. All rights reserved.
//

import UIKit

class DataDownloadViewController: UIViewController {

    @IBOutlet weak var progressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateProgress(_:)), name: .fileDownloadProgressUpdate, object: nil)
        // Do any additional setup after loading the view.
    }
    
    @objc func updateProgress(_ notification: NSNotification) {
        //print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            //print("1")
            if let data = dict["progress"] as? Double{
                //print("2")
                progressBar.progress = Float(data)
            }
        }
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

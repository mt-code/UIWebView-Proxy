//
//  ViewController.swift
//  UIWebView-Proxy
//
//  Created by Matthew Croston on 13/07/2018.
//  Copyright © 2018 MountCode. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var webview: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let req = URLRequest(url: URL(string: "http://api.ipify.org/")!) as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: "customkey", in: req)
        
        self.webview.loadRequest(req as URLRequest)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


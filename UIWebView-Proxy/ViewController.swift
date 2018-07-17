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
        let proxy   = Proxy(host: "213.32.113.36", port: 8080)
        let proxy2  = Proxy(host: "lon.uk.torguardvpnaccess.com", port: 6060, username: "ankco2n9g1gepzl", password: "MHP9D6C7LhkfH2O")
        
        let proxies = [proxy,proxy2]
        let randomIndex = Int(arc4random_uniform(UInt32(proxies.count)))
        
        //let req = URLRequest(url: URL(string: "https://api.ipify.org/")!) as! NSMutableURLRequest
        let req = URLRequest(url: URL(string: "https://whatsmyip.com/")!) as! NSMutableURLRequest
        URLProtocol.setProperty(proxies[randomIndex], forKey: "proxy", in: req)
        
        self.webviewTesting()
        return
        
        //self.webview.loadRequest(req as URLRequest)
    }
    
    func webviewTesting() {
        
        UserDefaults.standard.register(defaults: ["UserAgent": "Custom-Agent-1"])
        
        
        let webviewOne = UIWebView()
        print(webviewOne.stringByEvaluatingJavaScript(from: "navigator.userAgent"))
        
        UserDefaults.standard.register(defaults: ["UserAgent": "Custom-Agent-2"])
        
        let webviewTwo = UIWebView()
        print(webviewTwo.stringByEvaluatingJavaScript(from: "navigator.userAgent"))
        
        
        print("Final test:")
        print(webviewOne.stringByEvaluatingJavaScript(from: "navigator.userAgent"))
        print(webviewTwo.stringByEvaluatingJavaScript(from: "navigator.userAgent"))
    }
}


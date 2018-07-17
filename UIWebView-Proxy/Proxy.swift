//
//  Proxy.swift
//  UIWebView-Proxy
//
//  Created by Matthew Croston on 17/07/2018.
//  Copyright © 2018 MountCode. All rights reserved.
//

import Foundation

struct Proxy {
    var host: String
    var port: Int
    var username: String?
    var password: String?
    
    init(host: String, port: Int) {
        self.host   = host
        self.port   = port
    }
    
    init(host: String, port: Int, username: String, password: String) {
        self.host       = host
        self.port       = port
        self.username   = username
        self.password   = password
    }
}

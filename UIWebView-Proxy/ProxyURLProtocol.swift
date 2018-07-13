//
//  ProxyURLProtocol.swift
//  UIWebView-Proxy
//
//  Created by Matthew Croston on 13/07/2018.
//  Copyright © 2018 MountCode. All rights reserved.
//

import UIKit

class ProxyURLProtocol: URLProtocol, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    // Class variables.
    var dataTask: URLSessionDataTask?
    var receivedData: NSMutableData!
    var urlResponse: URLResponse!
    
    override class func canInit(with request: URLRequest) -> Bool {
        if URLProtocol.property(forKey: "processing", in: request) != nil {
            return false
        }
        
        print("Proxying request: \(request.url?.absoluteString)")
        
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let newRequest = self.request as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: "processing", in: newRequest) // Tag our request to show it is being processed.
        
        self.dataTask = self.createSession(proxied: true).dataTask(with: newRequest as URLRequest)
        self.dataTask!.resume()
    }
    
    override func stopLoading() {
        self.dataTask?.cancel()
        self.dataTask = nil
    }
    
    // MARK: - URLSessionDataDelegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        receivedData.append(data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        urlResponse = response
        receivedData = NSMutableData()
        completionHandler(.allow)
    }
    
    // MARK: - URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            if let nsError = error as NSError?, nsError.domain == kCFErrorDomainCFNetwork as String {
                print("Failed due to invalid proxy credentials.")
                
                let newRequest = self.request as! NSMutableURLRequest
                URLProtocol.setProperty(true, forKey: "processing", in: newRequest) // Tag our request to show it is being processed.
                
                self.dataTask?.cancel()
                self.dataTask = self.createSession(proxied: false).dataTask(with: newRequest as URLRequest)
                self.dataTask!.resume()
                return
            }
            
            
            print("AN ERROR OCCURED \(error.localizedDescription)")
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        // Do what ever you want like saveCachedResponse()
        client?.urlProtocolDidFinishLoading(self)
    }
    
    private func createSession(proxied: Bool) -> URLSession {
        
        let config = URLSessionConfiguration.ephemeral
        
        if (proxied) {
            let proxyHost: CFString = "213.32.113.36" as CFString // proxy server
            let proxyPort: CFNumber = 8080 as CFNumber // your port
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable: true,
                kCFNetworkProxiesHTTPProxy: proxyHost,
                kCFNetworkProxiesHTTPPort: proxyPort,
                "HTTPSEnable": 1,
                kCFStreamPropertyHTTPSProxyHost: proxyHost,
                kCFStreamPropertyHTTPSProxyPort: proxyPort
            ]
        }
        
        /*
         ADD AUTH:
            kCFProxyUsernameKey
            kCFProxyPasswordKey
        */
        
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        return session
    }
}

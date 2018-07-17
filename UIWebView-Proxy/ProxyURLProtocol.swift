//
//  ProxyURLProtocol.swift
//  UIWebView-Proxy
//
//  Created by Matthew Croston on 13/07/2018.
//  Copyright © 2018 MountCode. All rights reserved.
//

import UIKit

// https://stackoverflow.com/questions/19687191/ios-passing-custom-nsurl-to-nsurlprotocol
// https://stackoverflow.com/questions/8487581/uiwebview-ios5-changing-user-agent/8666438#8666438

class ProxyURLProtocol: URLProtocol, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    // Class variables.
    var proxy: Proxy?
    var urlResponse: URLResponse!
    var receivedData: NSMutableData!
    var dataTask: URLSessionDataTask?
    
    /**
     Determines whether our protocol subclass should handle the specific task.
    */
    override class func canInit(with request: URLRequest) -> Bool {
        // Only handle the request if a proxy object exists.
        if let _ = URLProtocol.property(forKey: "proxy", in: request) as? Proxy {
            return true
        }
        
        return false
    }
    
    /**
     Returns a canonical version of the specified request.
    */
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    /**
     Starst protocol-specific loading of the request.
    */
    override func startLoading() {
        // Create mutable version of our URLRequest.
        let request = self.request as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: "processing", in: request) // Tag our request to show it is being processed.
        
        // Guard our proxy object.
        guard let proxy = URLProtocol.property(forKey: "proxy", in: request as URLRequest) as? Proxy else {
            fatalError("Attempted to handle a URLRequest that doesn't have a proxy object.")
        }
        
        self.proxy = proxy
        self.dataTask = self.createSession(proxied: true).dataTask(with: request as URLRequest)
        self.dataTask!.resume()
    }
    
    /**
     Stops protocol-specific loading of the request.
    */
    override func stopLoading() {
        self.dataTask?.cancel()
        self.dataTask = nil
    }
    
    //
    // MARK: - URLSessionDataDelegate
    //
    
    /**
     The data task has received the initial reply (headers) from the server.
     
     - Parameter session:   The session containing the data task that received an initial reply.
     - Parameter dataTask:  The data task that received an initial reply.
     - Parameter response:  A URL response object populated with headers.
    */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        urlResponse = response
        receivedData = NSMutableData()
        completionHandler(.allow)
    }
    
    /**
     The data task has received some of the expected data.
     
     - Parameter session:   The session containing the data task that provided data.
     - Parameter dataTask:  The data task that provided data.
     - Parameter data:      A data object containing the transferred data.
    */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        receivedData.append(data)
    }
    
    //
    // MARK: - URLSessionTaskDelegate
    //
    
    /**
     Our task has finished transferring data.
     
     - Parameter session:   The session containing the task whose request finished transferring data.
     - Parameter task:      The task whose request finished transferring data.
     - Parameter error:     If an error occured, an error object indicating how the transfer failed, otherwise NULL.
    */
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Session completed")
        
        if let error = error {
            if let nsError = error as NSError?, nsError.domain == kCFErrorDomainCFNetwork as String {
                print("Failed due to invalid proxy details.")
                
                let newRequest = self.request as! NSMutableURLRequest
                URLProtocol.setProperty(true, forKey: "processing", in: newRequest) // Tag our request to show it is being processed.
                
                self.dataTask?.cancel()
                self.dataTask = self.createSession(proxied: false).dataTask(with: newRequest as URLRequest)
                self.dataTask!.resume()
                return
            }
            
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    /**
     An authentication request has been received from the remote server.
     
     - Parameter session:   The session containing the task whose request requires authentication.
     - Parameter task:      The task whose request requires authentication.
     - Parameter challenge: An object that contains the request for authentication.
    */
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Received authentication challenge.")
        
        /*let authMethod = challenge.protectionSpace.authenticationMethod
        guard authMethod == NSURLAuthenticationMethodHTTPBasic else {
            print("Authentication method isn't basic, it is: \(authMethod)")
            completionHandler(.performDefaultHandling, nil)
            return
        }*/
        
        guard let username = self.proxy?.username else {
            print("Proxy tried to authenticate but no username is provided.")
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let password = self.proxy?.password else {
            print("Proxy tried to authenticate but no password is provided.")
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let credential = URLCredential(user: username, password: password, persistence: .forSession)
        completionHandler(.useCredential, credential)
    }
    
    //
    //  MARK: - Private
    //
    
    /**
     Creates the URLSession that will be used for the current request.
     
     - Parameter proxied:   If true the request will use the attached proxy for the session.
    */
    private func createSession(proxied: Bool) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        
        // Check if the session should be proxied.
        if (proxied) {
            guard let proxy = self.proxy else {
                fatalError("Failed to unwrap our proxy object, did startLoading() execute?")
            }
            
            let proxyHost: CFString = proxy.host as CFString
            let proxyPort: CFNumber = proxy.port as CFNumber
            
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable: true,
                kCFNetworkProxiesHTTPProxy: proxyHost,
                kCFNetworkProxiesHTTPPort: proxyPort,
                "HTTPSEnable": 1,
                kCFStreamPropertyHTTPSProxyHost: proxyHost,
                kCFStreamPropertyHTTPSProxyPort: proxyPort
            ]
        }
        
        // Return our configured session.
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
}


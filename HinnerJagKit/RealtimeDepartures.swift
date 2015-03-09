//
//  RealtimeDepartures.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation

public class RealtimeDepartures
{
    let session: NSURLSession
    let realtimeKey = "bebfe14511a74ca5aef16db943ae8589"
    
    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.session = NSURLSession(configuration: configuration);
    }
    
    public func departuresFromStationId(stationId: Int, callback: ([Departure]?, error: NSError?) -> ()) {
        var realtimeApiQueue = dispatch_queue_create("realtime API queue", nil)
        dispatch_async(realtimeApiQueue, {
            self.performRealtimeApiReqForStation(stationId, callback)
        })
    }
    
    func performRealtimeApiReqForStation(stationId: Int, callback: ([Departure]?, error: NSError?) -> ()) {
        println("stationId = \(stationId)")
        let apiURL = NSURL(string: "http://api.sl.se/api2/realtimedepartures.json?key=\(self.realtimeKey)&siteid=\(stationId)&timewindow=5")
        
        let request = NSURLRequest(URL: apiURL!)
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                var JSONError: NSError?
                let responseDict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &JSONError) as NSDictionary
                if JSONError == nil {
                    if let allTypes = responseDict["ResponseData"] as NSDictionary? {
                        if let metros = allTypes["Metros"] as [NSDictionary]? {
                            var departureList = [Departure]()
                            for item in metros {
                                departureList.append(Departure(dict: item))
                            }
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                callback(departureList, error: nil)
                            })
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        callback(nil, error: JSONError)
                    })
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(nil, error: error)
                })
            }
        })
        task.resume()
    }
}

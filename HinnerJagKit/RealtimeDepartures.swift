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
//    let apiServer = "http://localhost:3000"
    let apiServer = "http://hinner-jag.herokuapp.com"
    
    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.session = NSURLSession(configuration: configuration);
    }
    
    public func departuresFromStation(station: Station, callback: ([Departure]?, error: NSError?) -> ()) {
        var realtimeApiQueue = dispatch_queue_create("realtime API queue", nil)
        dispatch_async(realtimeApiQueue, {
            self.performRealtimeApiReqForStation(station, callback: callback)
//            self.fetchDummyDepartureJsonData(station, callback)
        })
    }
    
    func fetchDummyDepartureJsonData(station: Station, callback: ([Departure]?, error: NSError?) -> ()) {
        println("Please note that dummy data is used for departures")
        let hinnerJagKitBundle = NSBundle(forClass: LocateStation.classForCoder())
        let testDeparturesFilePath = hinnerJagKitBundle.pathForResource("test_departures", ofType: "json")
        assert(nil != testDeparturesFilePath, "The file test_departures.json must be included in the test framework")
        let testDeparturesData = NSData(contentsOfFile: testDeparturesFilePath!)
        self.parseJsonDataToDepartures(testDeparturesData, station: station, callback: callback)
    }
    
    func performRealtimeApiReqForStation(station: Station, callback: ([Departure]?, error: NSError?) -> ()) {
        println("stationId = \(station.id)")
        let request = NSURLRequest(URL: NSURL(string: "\(self.apiServer)/api/realtimedepartures/\(station.id).json")!)
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                self.parseJsonDataToDepartures(data, station: station, callback: callback)
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(nil, error: error)
                })
            }
        })
        task.resume()
    }
    
    func parseJsonDataToDepartures(data: NSData?, station: Station, callback: ([Departure]?, error: NSError?) -> ()) {
        var JSONError: NSError?
        let responseDict = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: &JSONError) as! NSDictionary
        if JSONError == nil {
            if let allTypes = responseDict["ResponseData"] as! NSDictionary? {
                if let metros = allTypes["Metros"] as! [NSDictionary]? {
                    var departureList = [Departure]()
                    for item in metros {
                        departureList.append(Departure(dict: item, station: station))
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
    }
}

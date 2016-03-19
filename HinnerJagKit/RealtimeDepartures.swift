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
    // MARK: - Debug variables
    // Unit test will fail if any of these are true to prevent them from being checked in
    public let debugBackend = false
    public let debugJsonData = false

    // MARK: - Variables
    let session: NSURLSession
    let realtimeKey = "bebfe14511a74ca5aef16db943ae8589"
    
    public init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.session = NSURLSession(configuration: configuration);
    }
    
    public func departuresFromStation(station: Station, callback: ([Departure]?, error: NSError?) -> ()) {
        let realtimeApiQueue = dispatch_queue_create("realtime API queue", nil)
        dispatch_async(realtimeApiQueue, {
            if self.debugJsonData {
                self.fetchDummyDepartureJsonData(station, callback: callback)
            } else {
                self.performRealtimeApiReqForStation(station, callback: callback)
            }
        })
    }
    
    // MARK: - Fetch departure JSON data
    func fetchDummyDepartureJsonData(station: Station, callback: ([Departure]?, error: NSError?) -> ()) {
        print("Please note that dummy data is used for departures")
        // Used dummy data file
        let testFile = "test_departures"
//        testFile = "test_departures_9510_karlberg"
//        testFile = "test_departures_9530_stockholms_sodra"
//        testFile = "test_departures_9520_sodertalje_centrum"
//        testFile = "test_departures_9325_sundbyberg"
//        testFile = "test_departures_9180_farsta_strand"
        
        let hinnerJagKitBundle = NSBundle(forClass: LocateStation.classForCoder())
        let testDeparturesFilePath = hinnerJagKitBundle.pathForResource(testFile, ofType: "json")
        assert(nil != testDeparturesFilePath, "The file \(testFile).json must be included in the framework")
        let testDeparturesData = NSData(contentsOfFile: testDeparturesFilePath!)
        self.parseJsonDataToDepartures(testDeparturesData, station: station, callback: callback)
    }
    
    func performRealtimeApiReqForStation(station: Station, callback: ([Departure]?, error: NSError?) -> ()) {
        print("stationId = \(station.id)")
        let urlString = "https://api.sl.se/api2/realtimedepartures.json?key=\(realtimeKey)&timewindow=60&siteid=\(station.id)"
        let request = NSURLRequest(URL: NSURL(string: urlString)!)
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                self.parseJsonDataToDepartures(data, station: station, callback: callback)
            } else {
                print("Error from SL: \(error)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(nil, error: error)
                })
            }
        })
        task.resume()
    }
    
    // MARK: - Parse JSON data into Departures
    func parseJsonDataToDepartures(data: NSData?, station: Station, callback: ([Departure]?, error: NSError?) -> ()) {
        do {
            let responseDict = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            if let allTypes = responseDict["ResponseData"] as! NSDictionary? {
                var departureList = [Departure]()
                // Add Metro departures
                if let metros = allTypes["Metros"] as! [NSDictionary]? {
                    for item in metros {
                        departureList.append(Departure(dict: item, station: station))
                    }
                }
                // Add Train ("pendeltåg") departures
                if let metros = allTypes["Trains"] as! [NSDictionary]? {
                    for item in metros {
                        departureList.append(Departure(dict: item, station: station))
                    }
                }
                // Add Bus departures
                if let buses = allTypes["Buses"] as! [NSDictionary]? {
                    for item in buses {
                        // Check that we only get the bus lines we care about for this station
                        // TODO: Get list of ignored bus lines from CoreData for this station, use blacklist
                        departureList.append(Departure(dict: item, station: station))
                    }
                }
                // Add Tram departures
                if let trams = allTypes["Trams"] as! [NSDictionary]? {
                    for item in trams {
                        departureList.append(Departure(dict: item, station: station))
                    }
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(departureList, error: nil)
                })
            } else {
                print("Weird, expected 'ResponseData' in the response from SL")
                callback(nil, error: nil)
            }
        } catch let JSONError as NSError {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(nil, error: JSONError)
            })
        }
    }
}

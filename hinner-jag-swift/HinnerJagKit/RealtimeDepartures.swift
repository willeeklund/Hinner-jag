//
//  RealtimeDepartures.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation

open class RealtimeDepartures
{
    // MARK: - Debug variables
    // Unit test will fail if any of these are true to prevent them from being checked in
    public let debugBackend = false
    public let debugJsonData = false

    // MARK: - Variables
    let session: URLSession
    
    public init() {
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration);
    }
    
    open func departuresFromStation(_ station: Site, callback: @escaping ([Departure]?, _ error: NSError?) -> ()) {
        let realtimeApiQueue = DispatchQueue(label: "realtime API queue", attributes: [])
        realtimeApiQueue.async(execute: {
            if self.debugJsonData {
                self.fetchDummyDepartureJsonData(station, callback: callback)
            } else {
                self.performRealtimeApiReqForStation(station, callback: callback)
            }
        })
    }
    
    // MARK: - Fetch departure JSON data
    func fetchDummyDepartureJsonData(_ station: Site, callback: @escaping ([Departure]?, _ error: NSError?) -> ()) {
        print("Please note that dummy data is used for departures")
        // Used dummy data file
        let testFile = "test_departures"
//        testFile = "test_departures_9510_karlberg"
//        testFile = "test_departures_9530_stockholms_sodra"
//        testFile = "test_departures_9520_sodertalje_centrum"
//        testFile = "test_departures_9325_sundbyberg"
//        testFile = "test_departures_9180_farsta_strand"
        
        let hinnerJagKitBundle = Bundle(for: LocateStation.classForCoder())
        let testDeparturesFilePath = hinnerJagKitBundle.path(forResource: testFile, ofType: "json")
        assert(nil != testDeparturesFilePath, "The file \(testFile).json must be included in the framework")
        let testDeparturesData = try? Data(contentsOf: URL(fileURLWithPath: testDeparturesFilePath!))
        self.parseJsonDataToDepartures(testDeparturesData, station: station, callback: callback)
    }
    
    func performRealtimeApiReqForStation(_ station: Site, callback: @escaping ([Departure]?, _ error: NSError?) -> ()) {
        // Read configuration from plist file
        guard
            let bundle = Bundle(identifier: "com.wilhelmeklund.HinnerJagKit"),
            let configPath = bundle.path(forResource: "Config", ofType: "plist"),
            let configDict = NSDictionary(contentsOfFile: configPath),
            let realtimeKey = configDict["realtimeKey"] as? String
            else
        {
            print("Could not read config file with realtimeKey")
            fatalError()
        }
        let urlString = "https://api.sl.se/api2/realtimedeparturesV4.json?key=\(realtimeKey)&timewindow=60&siteid=\(station.siteId)"
        let request = URLRequest(url: URL(string: urlString)!)
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if error == nil && data != nil {
                self.parseJsonDataToDepartures(data!, station: station, callback: callback)
            } else {
                print("Error from SL: \(error)")
                DispatchQueue.main.async(execute: { () -> Void in
                    callback(nil, error as NSError?)
                })
            }
        })
        task.resume()
    }
    
    // MARK: - Parse JSON data into Departures
    func parseJsonDataToDepartures(_ data: Data?, station: Site, callback: @escaping ([Departure]?, _ error: NSError?) -> ()) {
        do {
            let responseDict = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
            if let allTypes = responseDict["ResponseData"]  as? NSDictionary {
                var departureList = [Departure]()
                // Add departure for the sections we want to use
                let transportTypeSection = ["Metros", "Trains", "Buses", "Trams", "Ships"]
                for section in transportTypeSection {
                    if let chosenSection = allTypes[section] as! [NSDictionary]? {
                        for item in chosenSection {
                            departureList.append(Departure(dict: item, station: station))
                        }
                    }
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    callback(departureList, nil)
                })
            } else {
                print("Weird, expected 'ResponseData' in the response from SL")
                callback(nil, nil)
            }
        } catch let JSONError as NSError {
            DispatchQueue.main.async(execute: { () -> Void in
                callback(nil, JSONError)
            })
        }
    }
}

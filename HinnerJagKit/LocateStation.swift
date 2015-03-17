//
//  LocateStation.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreLocation

public class LocateStation: NSObject, CLLocationManagerDelegate
{
    public lazy var stationList: [Station] = {
        var tmpList = [Station]()
        // Read bundled metro_stations.json and create station objects from it
        let hinnerJagKitBundle = NSBundle(forClass: self.classForCoder)
        let metroStationsFilePath = hinnerJagKitBundle.pathForResource("metro_stations", ofType: "json")
        assert(nil != metroStationsFilePath, "The file metro_stations.json must be included in the framework")
        let metroStationsData = NSData(contentsOfFile: metroStationsFilePath!)
        assert(nil != metroStationsData, "metro_stations.json must contain valid data")
        var JSONError: NSError?
        let responseDict = NSJSONSerialization.JSONObjectWithData(metroStationsData!, options: NSJSONReadingOptions.AllowFragments, error: &JSONError) as NSDictionary
        if let metroStationsList = responseDict["metro_stations"] as [NSDictionary]? {
            for stationInfo in metroStationsList {
                tmpList.append(Station(dict: stationInfo))
            }
        }

        return tmpList
    }()
    
    var locationManager: CLLocationManager! = CLLocationManager()
    
    var realtimeDeparturesObj = RealtimeDepartures()

    public var locationUpdatedCallback: ((station: Station?, departures: [Departure]?, error: NSError?) -> ())?

    // MARK: - Init
    public override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    public func startUpdatingLocation() {
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - Get location of the user
    public func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.locationManager.stopUpdatingLocation()
        let location = locations.last as CLLocation
        self.findClosestStationFromLocation(location)
    }
    
    public func findClosestStationFromLocation(location: CLLocation) {
        var closestStation = self.findStationClosestToLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude)
        assert(nil != closestStation, "No station was found")

        self.realtimeDeparturesObj.departuresFromStation(closestStation!) {
            (departures: [Departure]?, error: NSError?) -> () in
            // When we check that the user is reasonably close to ANY station,
            // this is a good place to send back possible errors
            if nil != self.locationUpdatedCallback {
                self.locationUpdatedCallback?(station: closestStation, departures: departures, error: nil)
            }
        }
    }
    
    public func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("ERROR - location manager: \(error)")
    }

    // Compare distance from all known stations, return closest one
    public func findStationClosestToLatitude(latitude: Double, longitude: Double) -> Station? {
        var userLocation = CLLocation(latitude: latitude, longitude: longitude)
        var closest: Station? = self.stationList.first
        var minDist = closest?.distanceFromLocation(userLocation)
        for station in self.stationList {
            let dist = station.distanceFromLocation(userLocation)
            if dist < minDist {
                minDist = dist
                closest = station
            }
        }
        return closest
    }
}

//
//  LocateStation.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreLocation

public protocol LocateStationDelegate {
    func locateStationFoundClosestStation(station: Station?)
    func locateStationFoundSortedStations(stationsSorted: [Station], withDepartures departures: [Departure]?, error: NSError?)
}

public class LocateStationBase: NSObject, CLLocationManagerDelegate
{
    public var delegate: LocateStationDelegate?
    
    public lazy var stationList: [Station] = {
        var tmpList = [Station]()
        // Read bundled metro_stations.json and create station objects from it
        let hinnerJagKitBundle = NSBundle(forClass: self.classForCoder)
        let metroStationsFilePath = hinnerJagKitBundle.pathForResource("metro_stations", ofType: "json")
        assert(nil != metroStationsFilePath, "The file metro_stations.json must be included in the framework")
        let metroStationsData = NSData(contentsOfFile: metroStationsFilePath!)
        assert(nil != metroStationsData, "metro_stations.json must contain valid data")
        let responseDict = try! NSJSONSerialization.JSONObjectWithData(metroStationsData!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
        // Choose types of stations to include
        let stationTypes = ["METROSTN", "RAILWSTN", "TRAMSTN", "FERRYBER", "BUSTERM_special"]
        for type in stationTypes {
            // Add stations
            if let metroStationsList = responseDict[type] as! [NSDictionary]? {
                for stationInfo in metroStationsList {
                    var info: NSMutableDictionary = stationInfo.mutableCopy() as! NSMutableDictionary
                    tmpList.append(Station(dict: info))
                }
            }
        }

        return tmpList
    }()
    
    public var locationManager: CLLocationManager! = CLLocationManager()
    
    var realtimeDeparturesObj = RealtimeDepartures()

    // MARK: - Init
    public override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    public func startUpdatingLocation() {}
    
    // MARK: - Get location of the user
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        if let location = locations.last {
            self.findClosestStationFromLocationAndFetchDepartures(location)
        }
    }

    public func findClosestStationFromLocation(location: CLLocation) -> [Station] {
        let closestStationsSorted = self.findStationsSortedClosestToLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude)
        return closestStationsSorted
    }

    public func findClosestStationFromLocationAndFetchDepartures(location: CLLocation) {
        let closestStationsSorted: [Station] = self.findClosestStationFromLocation(location)
        self.delegate?.locateStationFoundClosestStation(closestStationsSorted.first!)

        self.realtimeDeparturesObj.departuresFromStation(closestStationsSorted.first!) {
            (departures: [Departure]?, error: NSError?) -> () in
            // When we check that the user is reasonably close to ANY station,
            // this is a good place to send back possible errors
            self.delegate?.locateStationFoundSortedStations(closestStationsSorted, withDepartures: departures, error: nil)
        }
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("ERROR - location manager: \(error)")
    }

    // Compare distance from all known stations, return closest one
    public func findStationsSortedClosestToLatitude(latitude: Double, longitude: Double) -> [Station] {
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        var sortedStationList: [Station] = self.stationList
        sortedStationList.sortInPlace({ $0.distanceFromLocation(userLocation) < $1.distanceFromLocation(userLocation) })
        // Only return 4 stations
        return Array(sortedStationList[0...3])
    }
}

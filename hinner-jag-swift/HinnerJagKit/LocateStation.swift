//
//  LocateStation.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import CoreData

public protocol LocateStationDelegate {
    func locateStationFoundClosestStation(_ station: Site?)
    func locateStationFoundSortedStations(_ stationsSorted: [Site], withDepartures departures: [Departure]?, error: NSError?)
}

open class LocateStationBase: NSObject, CLLocationManagerDelegate
{
    open var delegate: LocateStationDelegate?
    
    open var locationManager: CLLocationManager! = CLLocationManager()
    
    var realtimeDeparturesObj = RealtimeDepartures()

    // MARK: - Init
    public override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    open func startUpdatingLocation() {
        // Show activity indicator
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.notificationEventActivityIndicator), object: nil, userInfo: [
            "show": true
        ])
    }
    
    // MARK: - Get location of the user
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        if let location = locations.last {
            self.findClosestStationFromLocationAndFetchDepartures(location)
        }
    }

    open func findClosestStationFromLocation(_ location: CLLocation) -> [Site] {
        let closestStationsSorted = self.findStationsSortedClosestToLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude)
        return closestStationsSorted
    }
    
    open func findClosestStationFromLocationAndFetchDepartures(_ location: CLLocation) {
        let closestStationsSorted: [Site] = self.findClosestStationFromLocation(location)
        self.findDeparturesFromStation(closestStationsSorted.first!, stationList: closestStationsSorted)
    }

    open func findDeparturesFromStation(_ station: Site, stationList: [Site]?) {
        // Show activity indicator
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.notificationEventActivityIndicator), object: nil, userInfo: [
            "show": true
        ])
        var usedStationList = stationList
        self.delegate?.locateStationFoundClosestStation(station)
        self.realtimeDeparturesObj.departuresFromStation(station) {
            (departures: [Departure]?, error: NSError?) -> () in
            // When we check that the user is reasonably close to ANY station,
            // this is a good place to send back possible errors
            if nil == stationList {
                let usedLocation = CLLocation(coordinate: station.coordinate, altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, timestamp: Date())
                usedStationList = self.findClosestStationFromLocation(usedLocation)
            }
            self.delegate?.locateStationFoundSortedStations(usedStationList!, withDepartures: departures, error: nil)
            // Hide activity indicator
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.notificationEventActivityIndicator), object: nil, userInfo: [
                "show": false
            ])
        }
    }
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR - location manager: \(error)")
    }

    // Compare distance from all known stations, return closest one
    open func findStationsSortedClosestToLatitude(_ latitude: Double, longitude: Double) -> [Site] {
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        var sortedStationList: [Site] = Site.getAllActiveSites()
        let optimalNumberOfStations = 5
        // If no station were within 5km, sort entire list
        var smallerList = sortedStationList.filter({station in
            // Only use the active stations
            return station.distanceFromLocation(userLocation) < 5000
        })
        if optimalNumberOfStations < smallerList.count {
            sortedStationList = smallerList
        }
        if smallerList.count >= 20 {
            smallerList = sortedStationList.filter({station in return station.distanceFromLocation(userLocation) < 1500})
            if optimalNumberOfStations < smallerList.count {
                sortedStationList = smallerList
            }
        }
        sortedStationList.sort(by: { $0.distanceFromLocation(userLocation) < $1.distanceFromLocation(userLocation) })
        
        // Only return 6 stations
        return Array(sortedStationList[0...min(optimalNumberOfStations, sortedStationList.count - 1)])
    }
}

//
//  Utils.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 29/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import MapKit

public class Utils
{
    // By casting the result of an Array.map first into a Set and then into Array,
    // duplicates of the same transport type are removed
    public class func uniqueTransportTypesFromDepartures(departures: [Departure]) -> [TransportType] {
        return Array(Set(departures.map({ dept in dept.transportType! })))
    }
    
    public class func currentTransportType(departures: [Departure]) -> TransportType {
        let uniqueTransportTypes = uniqueTransportTypesFromDepartures(departures)
        // If we have one of them as preferred, filter on that
        let preferredTransportType = getPreferredTransportType()
        if nil != preferredTransportType && uniqueTransportTypes.contains(preferredTransportType!) {
            return preferredTransportType!
        } else {
            // If there was no preferred, check if there is Metro,
            // otherwise use the first one from the list
            // of transport types existing in this departure list
            if uniqueTransportTypes.contains(.Metro) {
                return .Metro
            } else {
                return uniqueTransportTypes.first!
            }
        }
    }
    
    // Group departures and make a way to convert integers into mapping keys
    public class func getMappingFromDepartures(departures: [Departure], station: Station, mappingStart: Int = 0) -> (Dictionary <Int, String>, Dictionary<String, [Departure]>) {
        var largestUsedMapping: Int = mappingStart
        var mappingDict = Dictionary <Int, String>()
        var departuresDict = Dictionary <String, [Departure]>()
        
        // List of unique transport types available in list of departures
        let uniqueTransportTypes = Utils.uniqueTransportTypesFromDepartures(departures)
        if 0 == uniqueTransportTypes.count {
            return (mappingDict, departuresDict)
        }
        let currentTransportType = Utils.currentTransportType(departures)
        
        // Only use the departures of the preferred type
        for dept in departures.filter({ dept in nil != dept.transportType && currentTransportType == dept.transportType! }) {
            let mappingName = "\(dept.transportType!.rawValue) - \(dept.lineName) - riktning \(dept.direction)"
            if let _ = departuresDict[mappingName] {
                // Only add 4 departures to each group
                if departuresDict[mappingName]!.count < 4 {
                    departuresDict[mappingName]!.append(dept)
                }
            } else {
                mappingDict[largestUsedMapping++] = mappingName
                departuresDict[mappingName] = [Departure]()
                departuresDict[mappingName]?.append(dept)
            }
        }
        return (mappingDict, departuresDict)
    }
    
    public class func getLabelTextForClosestStation(station: Station?, ownLocation location: CLLocation?) -> String {
        if nil == station || nil == location {
            return "Söker efter plats..."
        } else {
            let distFormat = Utils.distanceFormat(station!.distanceFromLocation(location!))
            return "Närmast: \(station!.title!) (\(distFormat))"
        }
    }
    
    public class func distanceFormat(distance: Double) -> String {
        // Round to even 50m steps
        var dist = Int(distance / 50.0)
        dist *= 50
        var distString: String = "\(dist)m"

        switch dist {
        case _ where dist >= 1000:
            let dist100 = Int(dist / 100)
            let distKm = Double(dist100) / 10.0
            distString = "\(distKm)km"
        default: break
        }

        return distString
    }
    
    // MARK: - Keep track of preferred travel type for the user
    static let preferredTransportTypeKey = "preferredTransportTypeKey"
    public class func getPreferredTransportType() -> TransportType? {
        let preferredTravelTypeString = NSUserDefaults.standardUserDefaults().stringForKey(Utils.preferredTransportTypeKey)
        if nil != preferredTravelTypeString {
            return TransportType(rawValue: preferredTravelTypeString!)
        } else {
            return nil
        }
    }
    
    public class func setPreferredTransportType(type: TransportType) {
        NSUserDefaults.standardUserDefaults().setValue(type.rawValue, forKey: Utils.preferredTransportTypeKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

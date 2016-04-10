//
//  Utils.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 29/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import MapKit

/**
Utilities class to make small transformations etc used by all other classes
*/
public class Utils
{
    // MARK: - Transport types
    
    /**
    A list of all the unique TransportType objects in the list of Departures.
    
    - returns:
    An array of [TransportType]
    
    - parameters:
        - departures: List with the Departures to map

    By casting the result of an Array.map first into a Set and then into Array,
    duplicates of the same transport type are removed
    */
    public class func uniqueTransportTypesFromDepartures(departures: [Departure]) -> [TransportType] {
        return Array(Set(departures.map({ dept in dept.transportType! })))
    }
    
    /**
    Get the TransportType to be shown from the list of Departures.

    - returns:
    TransportType to be shown
    */
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
    
    // MARK: - Mapping departures
    
    /**
    Group departures and make a way to convert integers into mapping keys
    
    - returns:
    Tuple with two dictionaries for mapping

    The returned tuple contains both the dictionary to map integers to mapping string, and the dictionary
    to map these string into arrays of Departures. This is needed when showing the results in a table
    where the places are determined by the row number.
    */
    public class func getMappingFromDepartures(departures: [Departure], mappingStart: Int = 0) -> (Dictionary <Int, String>, Dictionary<String, [Departure]>) {
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
            // Do not group by direction for buses
            let directionString: String
            if nil != dept.transportType && .Bus == dept.transportType! {
                directionString = ""
            } else {
                directionString = "riktning \(dept.direction)"
            }
            let mappingName = "\(dept.transportType!.rawValue) - \(dept.lineName) \(directionString)"
            if let _ = departuresDict[mappingName] {
                // Only add 4 departures to each group
                if departuresDict[mappingName]!.count < 4 {
                    departuresDict[mappingName]!.append(dept)
                }
            } else {
                mappingDict[largestUsedMapping] = mappingName
                departuresDict[mappingName] = [Departure]()
                departuresDict[mappingName]?.append(dept)
                largestUsedMapping += 1
            }
        }
        return (mappingDict, departuresDict)
    }
    
    // MARK: - Small tranformation methods
    public class func getLabelTextForClosestStation(station: Station?, ownLocation location: CLLocation?) -> String {
        if nil == station || nil == location {
            return "Söker efter plats..."
        } else {
            let distFormat = Utils.distanceFormat(station!.distanceFromLocation(location!))
            return "Närmast: \(station!.title!) (\(distFormat))"
        }
    }
    
    /**
    Format a distance

    - returns:
    String with formatted distance in meters, for instance "200m" or "4.5km"

    - parameters:
        - distance: The distance to format
    */
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
    
    /**
    Human readable name for transport type
    */
    public class func transportTypeStringToName(transportType: TransportType) -> String {
        switch transportType {
        case .Metro: return "T-bana"
        case .Train: return "Pendeltåg"
        case .Bus:   return "Buss"
        case .Tram:  return "Tvärbana"
        case .Ship: return "Färja"
        }
    }
    
    // MARK: - Keep track of preferred transport type for the user
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

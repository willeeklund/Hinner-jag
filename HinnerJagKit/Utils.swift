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
    // Group departures and make a way to convert integers into mapping keys
    public class func getMappingFromDepartures(departures: [Departure], mappingStart: Int = 0) -> (Dictionary <Int, String>, Dictionary<String, [Departure]>) {
        var largestUsedMapping: Int = mappingStart
        var mappingDict = Dictionary <Int, String>()
        var departuresDict = Dictionary <String, [Departure]>()
        for dept in departures {
            let mappingName = "\(dept.lineName) - riktning \(dept.direction)"
            if let depList = departuresDict[mappingName] {
                departuresDict[mappingName]?.append(dept)
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
            return "Närmast: \(station!.title) (\(distFormat))"
        }
    }
    
    public class func distanceFormat(distance: Double) -> String {
        // Round to even 50m steps
        var dist = Int(distance / 50.0)
        dist *= 50
        var distString: String = "\(dist)m"

        switch dist {
        case _ where 1000 <= dist && dist < 10000:
            var dist100 = Int(dist / 100)
            var distKm = Double(dist100) / 10.0
            distString = "\(distKm)km"
        default: break
        }

        return distString
    }
}

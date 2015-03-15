//
//  SortDepartures.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 15/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation

public class SortDepartures {
    
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
    
}

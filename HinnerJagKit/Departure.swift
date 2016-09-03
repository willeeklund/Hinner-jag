//
//  Departure.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit

open class Departure: NSObject
{
    open var destination: String = ""
    open var remainingTime: String = ""
    open var direction: Int = 0
    open var lineNumber: String = ""
    open var lineName: String = ""
    open var transportType: TransportType?
    open var fromCentralDirection: Int?
    open var siteId = 0
    
    override open var description: String {
        get {
            return "Departure to \(self.destination) in \(self.remainingTime) going direction \(self.direction) with \(self.lineName)."
        }
    }
    
    public init(dict: NSDictionary, station: Site) {
        super.init()
        if let dest = dict["Destination"] as? String {
            destination = dest
        }
        if let time = dict["DisplayTime"] as? String {
            remainingTime = time
        }
        if let dir = dict["JourneyDirection"] as? Int {
            direction = dir
        }
        if let nbr = dict["LineNumber"] as? String {
            lineNumber = nbr
        }
        if let name = dict["GroupOfLine"] as? String {
            lineName = name
        }
        if let type = dict["TransportMode"] as? String {
            transportType = TransportType(rawValue: type)
            if nil != transportType && .Bus == transportType! {
                // This is currently used when creating groups of departures
                lineName = "\(lineName) nr \(lineNumber)"
            }
        }
        if let SiteId = dict["SiteId"] as? Int {
            siteId = SiteId
        }
        self.fromCentralDirection = Int(station.fromCentralDirection)
    }
    
    open class func createDirectionSuffix(
        _ sectionString: String,
        departuresDict: Dictionary<String, [Departure]>
        ) -> String {
            let suffixDestination: String
            if sectionString.range(of: "METRO") != nil {
                suffixDestination = "T-centralen"
            } else if sectionString.range(of: "TRAIN") != nil {
                suffixDestination = "Sthlm"
            } else if
                sectionString.range(of: "BUS") != nil
                || sectionString.range(of: "TRAM") != nil
            {
                // No direction suffix for buses or trams
                return ""
            } else {
                suffixDestination = ""
            }
            if let depList = departuresDict[sectionString] {
                let firstDep = depList[0]
                if firstDep.fromCentralDirection != nil {
                    var truthValue = firstDep.fromCentralDirection! == firstDep.direction
                    
                    // If both metros and trains station, reverse direction suffix for train departures.
                    // This is a hardcoded list of the siteids for stations with both subways and trains.
                    let isBothMetroAndTrains = [9001, 9325, 9180].contains(firstDep.siteId)
                    if isBothMetroAndTrains && nil != firstDep.transportType && .Train == firstDep.transportType! {
                        truthValue = !truthValue
                    }
                    
                    if truthValue {
                        return "från \(suffixDestination)"
                    } else {
                        return "mot \(suffixDestination)"
                    }
                } else {
                    // This probably means we are at T-centralen
                    if nil != firstDep.transportType && .Train == firstDep.transportType! {
                        return firstDep.lineName
                    }
                }
            }
            // If not departures were received or there is no 'fromCentralDirection'
            return ""
    }
    
    open class func createLabelAndImageNameFromSection(_ sectionString: String, departuresDict: Dictionary<String, [Departure]>) -> (String, String?, UIColor?) {
        // Metro groups
        if sectionString.range(of: TransportType.Metro.rawValue) != nil {
            if sectionString.range(of: "gröna") != nil {
                return ("Grön linje", "train_green", UIColor.green)
            } else if sectionString.range(of: "röda") != nil {
                return ("Röd linje", "train_red", UIColor.red)
            } else if sectionString.range(of: "blå") != nil {
                return ("Blå linje", "train_blue", UIColor.blue)
            } else {
                print("Can not decide direction label for '\(sectionString)'")
                return (Utils.transportTypeStringToName(.Metro), nil, nil)
            }
        }
        // Train groups
        else if sectionString.range(of: TransportType.Train.rawValue) != nil {
            return (Utils.transportTypeStringToName(.Train), "train_purple", UIColor.purple)
        }
        // Bus groups
        else if sectionString.range(of: TransportType.Bus.rawValue) != nil {
            if let depList = departuresDict[sectionString] {
                let firstDep = depList[0]
                return ("\(Utils.transportTypeStringToName(.Bus)) \(firstDep.lineNumber)", "bus", nil)
            } else {
                return (Utils.transportTypeStringToName(.Bus), "bus", nil)
            }
        }
        // Tram groups
        else if sectionString.range(of: TransportType.Tram.rawValue) != nil {
            return (Utils.transportTypeStringToName(.Tram), "train_orange", UIColor.orange)
        }
        // Ship groups
        else if sectionString.range(of: TransportType.Ship.rawValue) != nil {
            return (Utils.transportTypeStringToName(.Ship), "anchor", UIColor.blue)
        }
        return ("Okänd", nil, nil)
    }
    
    open class func getLineNumberAndTransportTypeFromSection(_ sectionString: String, departuresDict: Dictionary<String, [Departure]>) -> (Int?, TransportType?) {
        if let depList = departuresDict[sectionString] {
            let firstDep = depList[0]
            return (Int(firstDep.lineNumber), firstDep.transportType)
        } else {
            return (nil, nil)
        }
    }
    
}

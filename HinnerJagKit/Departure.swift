//
//  Departure.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit

public class Departure: NSObject
{
    public var destination: String = ""
    public var remainingTime: String = ""
    public var direction: Int = 0
    public var lineNumber: String = ""
    public var lineName: String = ""
    public var transportType: TransportType?
    public var fromCentralDirection: Int?
    public var siteId = 0
    
    override public var description: String {
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
            if nil != transportType && .Bus == transportType {
                // This is currently used when creating groups of departures
                lineName = "\(lineName) nr \(lineNumber)"
            }
        }
        if let SiteId = dict["SiteId"] as? Int {
            siteId = SiteId
        }
        self.fromCentralDirection = Int(station.fromCentralDirection)
    }
    
    public class func createDirectionSuffix(
        sectionString: String,
        departuresDict: Dictionary<String, [Departure]>
        ) -> String {
            let suffixDestination: String
            if sectionString.rangeOfString("METRO") != nil {
                suffixDestination = "T-centralen"
            } else if sectionString.rangeOfString("TRAIN") != nil {
                suffixDestination = "Sthlm"
            } else if
                sectionString.rangeOfString("BUS") != nil
                    || sectionString.rangeOfString("TRAM") != nil
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
    
    public class func createLabelAndImageNameFromSection(sectionString: String, departuresDict: Dictionary<String, [Departure]>) -> (String, String?, UIColor?) {
        // Metro groups
        if sectionString.rangeOfString(TransportType.Metro.rawValue) != nil {
            if sectionString.rangeOfString("gröna") != nil {
                return ("Grön linje", "train_green", UIColor.greenColor())
            } else if sectionString.rangeOfString("röda") != nil {
                return ("Röd linje", "train_red", UIColor.redColor())
            } else if sectionString.rangeOfString("blå") != nil {
                return ("Blå linje", "train_blue", UIColor.blueColor())
            } else {
                print("Can not decide direction label for '\(sectionString)'")
                return (Utils.transportTypeStringToName(.Metro), nil, nil)
            }
        }
        // Train groups
        else if sectionString.rangeOfString(TransportType.Train.rawValue) != nil {
            return (Utils.transportTypeStringToName(.Train), "train_purple", UIColor.purpleColor())
        }
        // Bus groups
        else if sectionString.rangeOfString(TransportType.Bus.rawValue) != nil {
            if let depList = departuresDict[sectionString] {
                let firstDep = depList[0]
                return ("\(Utils.transportTypeStringToName(.Bus)) \(firstDep.lineNumber)", "bus", nil)
            } else {
                return (Utils.transportTypeStringToName(.Bus), "bus", nil)
            }
        }
        // Tram groups
        else if sectionString.rangeOfString(TransportType.Tram.rawValue) != nil {
            return (Utils.transportTypeStringToName(.Tram), "train_orange", UIColor.orangeColor())
        }
        // Ship groups
        else if sectionString.rangeOfString(TransportType.Ship.rawValue) != nil {
            return (Utils.transportTypeStringToName(.Ship), "anchor", UIColor.blueColor())
        }
        return ("Okänd", nil, nil)
    }
    
}

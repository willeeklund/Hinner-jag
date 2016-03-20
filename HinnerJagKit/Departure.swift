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
    public var from_central_direction: Int?
    public var siteId = 0
    
    override public var description: String {
        get {
            return "Departure to \(self.destination) in \(self.remainingTime) going direction \(self.direction) with \(self.lineName)."
        }
    }
    
    public init(dict: NSDictionary, station: Station) {
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
        self.from_central_direction = station.from_central_direction
    }
    
}

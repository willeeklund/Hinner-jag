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
    public var lineNumber: Int = 0
    public var lineName: String = ""
    
    override public var description: String {
        get {
            return "Departure to \(self.destination) in \(self.remainingTime) going direction \(self.direction) with \(self.lineName)."
        }
    }
    
    public init(dict: NSDictionary) {
        super.init()
        if let dest = dict["Destination"] as? String {
            self.destination = dest
        }
        if let time = dict["DisplayTime"] as? String {
            self.remainingTime = time
        }
        if let dir = dict["JourneyDirection"] as? Int {
            self.direction = dir
        }
        if let nbr = dict["LineNumber"] as? Int {
            self.lineNumber = nbr
        }
        if let name = dict["GroupOfLine"] as? String {
            self.lineName = name
        }
    }
    
}
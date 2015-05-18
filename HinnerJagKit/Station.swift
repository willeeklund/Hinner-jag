//
//  Station.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public enum StationType: Int {
    case Metro = 0
    case Train = 1
    case MetroAndTrain = 2
    
    public func description() -> String {
        if self == .Metro {
            return "*Metro*"
        } else if self == .Train {
            return "*Train*"
        } else if self == .MetroAndTrain {
            return "*MetroAndTrain*"
        } else {
            return "*Unknown*"
        }
    }
}

public class Station: CLLocation, MKAnnotation
{
    public var id: Int = 0
    public var title: String = ""
    public var from_central_direction: Int?
    public var stationType: StationType?
    
    private func typeOfStation() -> String {
        // StationType has not been set
        if nil == self.stationType {
            return "Station"
        }
        // Description of station type
        switch self.stationType! {
        case .Metro: return "Metro station"
        case .Train: return "Train station"
        case .MetroAndTrain: return "Metro and train station"
        }
    }
    
    override public var description: String {
        get {
            return "\(self.typeOfStation()) \(self.id): \(self.title) at (\(self.coordinate.latitude), \(self.coordinate.longitude))"
        }
    }
    
    public init(dict: NSDictionary) {
        // Hopefully we can read info from the dictionary, otherwise use defaults
        var usedLatitude = 0.0
        if let dictLatitude = dict["latitude"] as! Double? {
            usedLatitude = dictLatitude
        }
        var usedLongitude = 0.0
        if let dictLongitude = dict["longitude"] as! Double? {
            usedLongitude = dictLongitude
        }

        var usedId = 0
        if let dictId = dict["siteid"] as! Int? {
            usedId = dictId
        }

        var usedTitle = ""
        if let dictTitle = dict["sitename"] as! String? {
            usedTitle = dictTitle
        }
        
        if let dictFromCentralDirection = dict["from_central_direction"] as! Int? {
            self.from_central_direction = dictFromCentralDirection
        }
        
        var usedStationType: StationType?
        if let dictStationTypeString = dict["stationType"] as? String {
            if "Train" == dictStationTypeString {
                usedStationType = .Train
            } else if "Metro" == dictStationTypeString {
                usedStationType = .Metro
            } else if "MetroAndTrain" == dictStationTypeString {
                usedStationType = .MetroAndTrain
            }
        }
        
        // Assert that we got real data
        assert(0.0 != usedLatitude, "Must set real latitude")
        assert(0.0 != usedLongitude, "Must set real longitude")
        assert(usedLatitude != usedLongitude, "We suspect coding error if latitude == longitude")
        assert(0   != usedId, "Must set real id")
        assert(""  != usedTitle, "Must set real title")
        assert(nil != usedStationType, "Every station must have a station type specified")

        // Create instance
        super.init(coordinate: CLLocationCoordinate2D(latitude: usedLatitude, longitude: usedLongitude), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, timestamp: NSDate())
        self.id = usedId
        self.title = usedTitle
        self.stationType = usedStationType
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

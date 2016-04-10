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

public enum TransportType: String {
    case Metro = "METRO"
    case Train = "TRAIN"
    case Bus = "BUS"
    case Tram = "TRAM"
    case Ship = "SHIP"

    public static func getRawValue(type: TransportType) -> String {
        return type.rawValue
    }
}

public class Station: CLLocation, MKAnnotation
{
    public var id: Int = 0
    public var title: String? = ""
    public var from_central_direction: Int?
    
    override public var description: String {
        get {
            return "Station \(self.id): \(self.title!) at (\(self.coordinate.latitude), \(self.coordinate.longitude))"
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
        
        // Assert that we got real data
        assert(0.0 != usedLatitude, "Must set real latitude")
        assert(0.0 != usedLongitude, "Must set real longitude")
        assert(usedLatitude != usedLongitude, "We suspect coding error if latitude == longitude")
        assert(0   != usedId, "Must set real id")
        assert(""  != usedTitle, "Must set real title")

        // Create instance
        super.init(coordinate: CLLocationCoordinate2D(latitude: usedLatitude, longitude: usedLongitude), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, timestamp: NSDate())
        self.id = usedId
        self.title = usedTitle
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

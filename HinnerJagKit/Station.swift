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

public class Station: CLLocation, MKAnnotation
{
    public var id: Int = 0
    public var title: String = ""
    
    override public var description: String {
        get {
            return "Station \(self.id): \(self.title) \(self.coordinate)"
        }
    }
    
    public init(id: Int, latitude: Double, longitude: Double, title: String) {
        super.init(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, timestamp: NSDate())
        self.id = id
        self.title = title
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

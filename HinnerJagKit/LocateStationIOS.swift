//
//  LocateStationIOS.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 27/10/15.
//  Copyright © 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation

open class LocateStation: LocateStationBase {
    open override func startUpdatingLocation() {
        super.startUpdatingLocation()
        self.locationManager.startUpdatingLocation()
    }
}

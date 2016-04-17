//
//  LocateStationIOS.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 27/10/15.
//  Copyright © 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation

public class LocateStation: LocateStationBase {
    public override func startUpdatingLocation() {
        self.locationManager.startUpdatingLocation()
    }
}

//
//  LocateStation.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreLocation

public class LocateStation
{
    lazy var stationList: [Station] = {
        var tmpList = [Station]()
        // Manually add stations to list for now
        tmpList.append(Station(id: 9109, latitude: 59.3382848826814, longitude: 17.9396416118668, title: "Brommaplan"))
        tmpList.append(Station(id: 9110, latitude: 59.3365630909855, longitude: 17.9531728536484, title: "Abrahamsberg"))
        tmpList.append(Station(id: 9112, latitude: 59.3335288880974, longitude: 17.9812769147661, title: "Alvik"))
        tmpList.append(Station(id: 9113, latitude: 59.3327232981679, longitude: 18.0030706383360, title: "Kristineberg"))
        tmpList.append(Station(id: 9116, latitude: 59.3402934026792, longitude: 18.0374161430336, title: "S:t Eriksplan"))
        tmpList.append(Station(id: 9001, latitude: 59.3323449133058, longitude: 18.0620091038496, title: "T-Centralen"))
        tmpList.append(Station(id: 9192, latitude: 59.3195772927204, longitude: 18.0717389396459, title: "Slussen"))
        tmpList.append(Station(id: 9119, latitude: 59.3356060415282, longitude: 18.0629635851674, title: "Hötorget"))
        tmpList.append(Station(id: 9206, latitude: 59.3349688288931, longitude: 18.0763846822514, title: "Östermalmstorg"))
        //        tmpList.append(Station(id: , latitude: , longitude: , title: ""))
        return tmpList
    }()

    public init() {
        println("LocateStation.init()")
    }

    public func findStationClosestToLatitude(latitude: Double, longitude: Double) -> Station? {
        var userLocation = CLLocation(latitude: latitude, longitude: longitude)
        var closest: Station? = self.stationList.first
        var minDist = closest?.distanceFromLocation(userLocation)
        for station in self.stationList {
            let dist = station.distanceFromLocation(userLocation)
            if dist < minDist {
                minDist = dist
                closest = station
            }
        }
        return closest
    }
}

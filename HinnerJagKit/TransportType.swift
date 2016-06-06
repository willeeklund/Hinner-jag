//
//  TransportType.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 13/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation

public enum TransportType: String {
    case Metro = "METRO"
    case Train = "TRAIN"
    case Tram  = "TRAM"
    case Ship  = "SHIP"
    case Bus   = "BUS"
    
    public func stopAreaTypeCode() -> String {
        switch self {
        case .Metro: return "METROSTN"
        case .Train: return "RAILWSTN"
        case .Tram:  return "TRAMSTN"
        case .Ship:  return "SHIPBER"
        case .Bus:   return "BUSTERM"
        }
    }
    
    public static func all() -> [TransportType] {
        return [.Metro, .Train, .Tram, .Ship, .Bus]
    }
}

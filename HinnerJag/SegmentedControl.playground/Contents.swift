//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
let tintColor = UIColor(red: 1.0/255.0, green: 152.0/255.0, blue: 117.0/255.0, alpha: 1)

let lbl = UILabel(frame: CGRectMake(0, 0, 300, 100))
lbl.text = "Hello StackOverflow!"

public enum StationType: String {
    case Metro = "METRO"
    case Train = "TRAIN"
    case Bus = "BUS"
    case Tram = "TRAM"
    
    public func description() -> String {
        return self.rawValue
    }
}

func transportTypeStringToName(typeString: String) -> String {
    let stationType = StationType(rawValue: typeString)
    if nil == stationType {
        return typeString
    }
    switch stationType! {
    case .Metro: return "Tunnelbana"
    case .Train: return "Pendeltåg"
    case .Bus: return "Buss"
    case .Tram: return "Tvärbana"
    }
}

let transportTypes = ["METRO", "TRAIN", "TRAM", "BUS"]
let namesList = transportTypes.map() { (typeString) in
    return transportTypeStringToName(typeString)
}
let segment = UISegmentedControl(items: namesList)
segment.frame = CGRectMake(0, 0, 320, 30)
segment.selectedSegmentIndex = 0


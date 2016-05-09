//: Playground - noun: a place where people can play

import UIKit
import CoreData
import HinnerJagKit

var str = "SortMappingDict playground"
var largestUsedMapping: Int = 1
let mappingDict: Dictionary <Int, String> = [
    1: "Bus 8",
    2: "Bus 2 - STAR",
    3: "Bus 17",
    4: "Bus 5 - STAR",
    5: "Bus 3"
]

let mappingStringsSorted = mappingDict.values.sort() {
    let firstStar = $0.rangeOfString("STAR") != nil
    let secondStar = $1.rangeOfString("STAR") != nil
    if (firstStar && secondStar) || (!firstStar && !secondStar) {
        return $0 < $1
    } else if firstStar {
        return true
    } else if secondStar {
        return false
    }
    return $0 < $1
}

var newMappingDict = Dictionary<Int, String>()
for mappingString in mappingStringsSorted {
    newMappingDict[largestUsedMapping] = mappingString
    largestUsedMapping += 1
}

newMappingDict[1]
newMappingDict[2]
newMappingDict[3]
newMappingDict[4]
newMappingDict[5]

print("Success!")
print(newMappingDict)

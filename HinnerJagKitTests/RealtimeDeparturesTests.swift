//
//  RealtimeDeparturesTests.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 08/12/15.
//  Copyright © 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import XCTest
@testable import HinnerJagKit

class RealtimeDeparturesTests: XCTestCase {
    var realtimeDepartures: RealtimeDepartures?
    var stationFarstaStrand: Station?
    let hinnerJagKitBundle = NSBundle(forClass: LocateStation.classForCoder())
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        realtimeDepartures = RealtimeDepartures()
        let dict = NSMutableDictionary()
        dict.setValue(9180, forKey: "siteid")
        dict.setValue("Farsta strand fake", forKey: "sitename")
        dict.setValue("Metro", forKey: "stationType")
        dict.setValue(59.2355276839029, forKey: "latitude")
        dict.setValue(18.1012808998205, forKey: "longitude")
        dict.setValue(2, forKey: "from_central_direction")
        stationFarstaStrand = Station(dict: dict)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func readTestFile(testFile: String) -> NSData {
        let testDeparturesFilePath = hinnerJagKitBundle.pathForResource(testFile, ofType: "json")
        assert(nil != testDeparturesFilePath, "The file \(testFile).json must be included in the framework")
        let testDeparturesData = NSData(contentsOfFile: testDeparturesFilePath!)
        return testDeparturesData!
    }
    
    func testParseJsonDataToDepartures() {
        let expectation = self.expectationWithDescription("Can parse JSON files")
        let testFile = "test_departures_9180_farsta_strand"
        let testDeparturesData = readTestFile(testFile)
        var depList: [Departure]?
        realtimeDepartures!.parseJsonDataToDepartures(testDeparturesData, station: stationFarstaStrand!) { (departures: [Departure]?, error: NSError?) in
            depList = departures
            XCTAssert(departures != nil, "We got some departures")
            XCTAssert(departures!.count > 0, "At least one departure")
            let (_, departuresDict) = Utils.getMappingFromDepartures(departures!, station: self.stationFarstaStrand!, mappingStart: 0)
            XCTAssert(departuresDict.count == 1, "There are exactly 2 groups of departures from Abrahamsberg")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(200) { (error) in
            XCTAssert(depList != nil, "We got some departures")
        }
    }

    func testParseBadDataToDepartures() {
        let expectation = self.expectationWithDescription("Can handle bad JSON file")
        let testDeparturesData = "No useful data".dataUsingEncoding(NSUTF8StringEncoding)
        
        var depList: [Departure]?
        realtimeDepartures!.parseJsonDataToDepartures(testDeparturesData, station: stationFarstaStrand!) { (departures: [Departure]?, error: NSError?) in
            depList = departures
            XCTAssert(error != nil, "We got an error message")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(200) { (error) in
            XCTAssert(depList == nil, "We did not get any departures from bad data")
        }
    }

    
}

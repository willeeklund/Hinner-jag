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
    var realtimeDepartures = RealtimeDepartures()
    var stationFarstaStrand: Site?
    let hinnerJagKitBundle = Bundle(for: LocateStation.self)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        realtimeDepartures = RealtimeDepartures()
        let dict = NSMutableDictionary()
        dict.setValue(9180, forKey: "SiteId")
        dict.setValue("Farsta strand fake", forKey: "SiteName")
        dict.setValue(59.2355276839029, forKey: "latitude")
        dict.setValue(18.1012808998205, forKey: "longitude")
        dict.setValue(2, forKey: "from_central_direction")
        stationFarstaStrand = Site(dict: dict)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func readTestFile(testFile: String) -> Data {
        let testDeparturesFilePath = hinnerJagKitBundle.path(forResource: testFile, ofType: "json")
        assert(nil != testDeparturesFilePath, "The file \(testFile).json must be included in the framework")
        let testDeparturesData = NSData(contentsOfFile: testDeparturesFilePath!)
        return testDeparturesData! as Data
    }
    
    func testParseJsonDataToDepartures() {
        let expectation = self.expectation(description: "Can parse JSON files")
        let testFile = "test_departures_9180_farsta_strand"
        let testDeparturesData = readTestFile(testFile: testFile)
        var depList: [Departure]?
        realtimeDepartures.parseJsonDataToDepartures(testDeparturesData, station: stationFarstaStrand!) { (departures: [Departure]?, error: NSError?) in
            depList = departures
            XCTAssert(departures != nil, "We got some departures")
            XCTAssert(departures!.count > 0, "At least one departure")
            let (_, departuresDict) = Utils.getMappingFromDepartures(departures!, mappingStart: 0)
            XCTAssert(departuresDict.count == 1, "There are exactly 2 groups of departures from Abrahamsberg")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 200) { (error) in
            XCTAssert(depList != nil, "We got some departures")
        }
    }

    func testParseBadDataToDepartures() {
        let expectation = self.expectation(description: "Can handle bad JSON file")
        let testDeparturesData = "No useful data".data(using: String.Encoding.utf8)
        
        var depList: [Departure]?
        realtimeDepartures.parseJsonDataToDepartures(testDeparturesData, station: stationFarstaStrand!) { (departures: [Departure]?, error: NSError?) in
            depList = departures
            XCTAssert(error != nil, "We got an error message")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 200) { (error) in
            XCTAssert(depList == nil, "We did not get any departures from bad data")
        }
    }

    
}

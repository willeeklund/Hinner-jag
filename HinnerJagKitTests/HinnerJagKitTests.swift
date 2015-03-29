//
//  HinnerJagKitTests.swift
//  HinnerJagKitTests
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import XCTest
import HinnerJagKit

class HinnerJagKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testLocatingAbrahamsberg() {
        var locateStation = LocateStation()
        let closestSortedStations: [Station] = locateStation.findStationsSortedClosestToLatitude(59.3365630909855, longitude: 17.9531728536484)
        var closest = closestSortedStations.first
        
        XCTAssert(nil != closest, "Can find a station")
        XCTAssert(closest!.title == "Abrahamsberg", "Can find Abrahamsbergs station")
        XCTAssert(closest!.id == 9110, "Can find correct SiteId for Abrahamsberg")
    }
    
    func testMetroStationListIsValid() {
        var locateStation = LocateStation()
        XCTAssert(locateStation.stationList.count >= 100, "At least 100 stations could be parsed from metro_stations.json")
    }
    
    func testFetchingResultsFromAPI() {
        let expectation = self.expectationWithDescription("Can fetch from the API")
        let realtimeDepartures = RealtimeDepartures()
        var depList: [Departure]?
        var abDict = NSMutableDictionary()
        abDict.setValue(9110, forKey: "siteid")
        abDict.setValue("Abrahamsberg fake", forKey: "sitename")
        abDict.setValue(59.3365630909855, forKey: "latitude")
        abDict.setValue(17.9531728536484, forKey: "longitude")
        abDict.setValue(1, forKey: "from_central_direction")

        let abrahamsbergStation = Station(dict: abDict)
        realtimeDepartures.departuresFromStation(abrahamsbergStation) { (departures: [Departure]?, error: NSError?) in
            depList = departures
            XCTAssert(departures != nil, "We got some departures")
            XCTAssert(departures!.count > 0, "At least one departure")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2000) { (error) in
            XCTAssert(depList != nil, "We got some departures")
        }
    }
}

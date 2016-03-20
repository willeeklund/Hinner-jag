//
//  UtilsTests.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 19/03/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import XCTest
@testable import HinnerJagKit

class UtilsTests: XCTestCase {
    
    var testDepartures: Dictionary<String, [Departure]> = [
        "metro": [Departure](),
        "bus": [Departure](),
        "tram": [Departure](),
        "train": [Departure]()
    ]
    
    override func setUp() {
        super.setUp()
        // Test station
        let dict = NSMutableDictionary()
        dict.setValue(9180, forKey: "siteid")
        dict.setValue("Farsta strand fake", forKey: "sitename")
        dict.setValue(59.2355276839029, forKey: "latitude")
        dict.setValue(18.1012808998205, forKey: "longitude")
        dict.setValue(2, forKey: "from_central_direction")
        let stationFarstaStrand = Station(dict: dict)
        // Departures: metro
        let metro1 = Departure(
            dict: [
                "StopAreaName": "Farsta strand",
                "GroupOfLine": "Tunnelbanans gröna linje",
                "DisplayTime": "6 min",
                "SafeDestinationName": "Alvik",
                "GroupOfLineId": 1,
                "DepartureGroupId": 1,
                "TransportMode": "METRO",
                "LineNumber": "18",
                "Destination": "Alvik",
                "JourneyDirection": 1,
                "SiteId": 9180
            ],
            station: stationFarstaStrand
        )
        let metro2 = Departure(
            dict: [
                "StopAreaName": "Farsta strand",
                "GroupOfLine": "Tunnelbanans gröna linje",
                "DisplayTime": "21:30",
                "SafeDestinationName": "Alvik",
                "GroupOfLineId": 1,
                "DepartureGroupId": 1,
                "TransportMode": "METRO",
                "LineNumber": "18",
                "Destination": "Alvik",
                "JourneyDirection": 1,
                "SiteId": 9180
            ],
            station: stationFarstaStrand
        )
        // Departures: bus
        let bus1 = Departure(
            dict: [
                "JourneyDirection": 2,
                "StopAreaName": "Farsta strand",
                "StopAreaNumber": 13264,
                "StopPointNumber": 70660,
                "StopPointDesignation": "A",
                "TimeTabledDateTime": "2016-03-20T21:05:00",
                "ExpectedDateTime": "2016-03-20T21:05:00",
                "DisplayTime": "9 min",
                "TransportMode": "BUS",
                "LineNumber": "742",
                "Destination": "Huddinge sjukhus",
                "SiteId": 9180
            ],
            station: stationFarstaStrand
        )
        let bus2 = Departure(
            dict: [
                "JourneyDirection": 1,
                "StopAreaName": "Farsta strand",
                "StopAreaNumber": 13264,
                "StopPointNumber": 70660,
                "StopPointDesignation": "A",
                "TimeTabledDateTime": "2016-03-20T21:15:23",
                "ExpectedDateTime": "2016-03-20T21:17:16",
                "DisplayTime": "22 min",
                "TransportMode": "BUS",
                "LineNumber": "181",
                "Destination": "Skarpnäck",
                "SiteId": 9180
            ],
            station: stationFarstaStrand
        )
        // Departures: train
        let train1 = Departure(
            dict: [
                "JourneyDirection": 2,
                "SecondaryDestinationName": "Stockholm C",
                "StopAreaName": "Farsta strand",
                "StopAreaNumber": 6121,
                "StopPointNumber": 6122,
                "StopPointDesignation": "1",
                "TimeTabledDateTime": "2016-03-20T21:10:00",
                "ExpectedDateTime": "2016-03-20T21:10:00",
                "DisplayTime": "14 min",
                "TransportMode": "TRAIN",
                "LineNumber": "35",
                "Destination": "Bålsta",
                "SiteId": 9180
            ],
            station: stationFarstaStrand
        )
        let train2 = Departure(
            dict: [
                "JourneyDirection": 1,
                "StopAreaName": "Farsta strand",
                "StopAreaNumber": 6121,
                "StopPointNumber": 6121,
                "StopPointDesignation": "2",
                "TimeTabledDateTime": "2016-03-20T21:19:00",
                "ExpectedDateTime": "2016-03-20T21:19:00",
                "DisplayTime": "23 min",
                "TransportMode": "TRAIN",
                "LineNumber": "35",
                "Destination": "Nynäshamn",
                "SiteId": 9180
            ],
            station: stationFarstaStrand
        )
        // Append test departures
        testDepartures["metro"]!.append(metro1)
        testDepartures["metro"]!.append(metro2)
        testDepartures["bus"]!.append(bus1)
        testDepartures["bus"]!.append(bus2)
        testDepartures["train"]!.append(train1)
        testDepartures["train"]!.append(train2)
    }
    
    override func tearDown() {
        // Clear user defaults for preferred transport type
        NSUserDefaults.standardUserDefaults().removeObjectForKey("preferredTransportTypeKey")
        super.tearDown()
    }
    
    // MARK: - Unique transport types for departures
    /**
     Tests for the unique transport types
     - empty list of departures
     - identical departures sent in multiple times
     - departures with the same transport type
     - departures with different transport type
     */
    func testUniqueTransportTypesFromDeparturesSingle() {
        let typesFromEmpty = Utils.uniqueTransportTypesFromDepartures([Departure]())
        XCTAssert(typesFromEmpty == [], "Empty list of departures")
        
        let typesFromMetro = Utils.uniqueTransportTypesFromDepartures([testDepartures["metro"]![0]])
        XCTAssert(typesFromMetro == [.Metro], "Metro departure, single")
    }
    
    func testUniqueTransportTypesFromDeparturesMultiple() {
        let typesFromMetroMultiple = Utils.uniqueTransportTypesFromDepartures(testDepartures["metro"]!)
        XCTAssert(typesFromMetroMultiple == [.Metro], "Metro departure, multiple")
        
        let typesFromMetroAndBus = Utils.uniqueTransportTypesFromDepartures(
            testDepartures["metro"]! + testDepartures["bus"]!
        )
        XCTAssert(typesFromMetroAndBus == [.Bus, .Metro], "Metro and bus departures")
        
        let typesFromMetroAndBusAndTrain = Utils.uniqueTransportTypesFromDepartures(
            testDepartures["metro"]! + testDepartures["bus"]! + testDepartures["train"]!
        )
        XCTAssert(typesFromMetroAndBusAndTrain.count == 3, "MetroBusTrain list has length 3")
        XCTAssert(typesFromMetroAndBusAndTrain.contains(.Metro), "MetroBusTrain list has .Metro")
        XCTAssert(typesFromMetroAndBusAndTrain.contains(.Bus), "MetroBusTrain list has .Bus")
        XCTAssert(typesFromMetroAndBusAndTrain.contains(.Train), "MetroBusTrain list has .Train")
    }
    
    // MARK: - Transport type
    /**
    Test to determine what transport type to use
    - no userdefaults set
    - userdefault that do not exist in list of departures
     */
    func testCurrentTransportTypeDefault() {
        XCTAssert(Utils.currentTransportType(testDepartures["metro"]!) == .Metro, "Single transport type: Metro")
        XCTAssert(Utils.currentTransportType(testDepartures["bus"]!) == .Bus, "Single transport type: Bus")
        let metrosAndBuses = testDepartures["metro"]! + testDepartures["bus"]!
        XCTAssert(Utils.currentTransportType(metrosAndBuses) == .Metro, "Default transport type is Metro")
    }
    
    func testCurrentTransportTypeHasPreference() {
        Utils.setPreferredTransportType(.Bus)
        let metrosAndBuses = testDepartures["metro"]! + testDepartures["bus"]!
        XCTAssert(Utils.currentTransportType(metrosAndBuses) == .Bus, "Preferred transport type is Bus")
    }
    
    func testCurrentTransportTypeOtherPreference() {
        Utils.setPreferredTransportType(.Train)
        let metrosAndBuses = testDepartures["metro"]! + testDepartures["bus"]!
        XCTAssert(Utils.currentTransportType(metrosAndBuses) == .Metro, "Other preference than the departures")
    }
    
    func testGetPreferredTransportTypeErased() {
        XCTAssert(nil == Utils.getPreferredTransportType(), "No default transport type was set")
    }
    
    func testSetPreferredTransportType() {
        Utils.setPreferredTransportType(.Bus)
        XCTAssert(.Bus == Utils.getPreferredTransportType(), "Can change transport type to Bus")
        Utils.setPreferredTransportType(.Metro)
        XCTAssert(.Metro == Utils.getPreferredTransportType(), "Can change transport type to Metro")
    }
    
    // MARK: - Mapping departures
    func testMappingDepartures() {
        Utils.setPreferredTransportType(.Bus)
        self.measureBlock() {
            let (mappingDict, departuresDict) = Utils.getMappingFromDepartures(
                self.testDepartures["metro"]! + self.testDepartures["bus"]! + self.testDepartures["train"]!,
                mappingStart: 0
            )
            XCTAssert(mappingDict.count == 2, "Only use the departures for preferred transport type in mapping dictionary")
            XCTAssert(departuresDict.count == 2, "Only use the departures for preferred transport type in mapping dictionary")
        }
    }
}

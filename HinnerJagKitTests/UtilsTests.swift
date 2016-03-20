//
//  UtilsTests.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 19/03/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import XCTest

class UtilsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUniqueTransportTypesFromDepartures() {
        /**
        Tests for the unique transport types
        
        * empty list of departures
        * identical departures sent in multiple times
        * departures with the same transport type
        * departures with different transport type
        
         */
    }
    
    func testCurrentTransportType() {
        /**
        Test to determine what transport type to use
        
        * no userdefaults set
        * userdefault that do not exist in list of departures
        * userdefaults set which are not a valid TransportType
        
         */
    }
    
}

//
//  InterfaceController.swift
//  Hinner jag? WatchKit Extension
//
//  Created by Wilhelm Eklund on 14/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import WatchKit
import Foundation
import HinnerJagKit

class InterfaceController: WKInterfaceController, CLLocationManagerDelegate, LocateStationDelegate {
    // MARK: - Variables
    var mappingDict: Dictionary <Int, String> = Dictionary <Int, String>()
    var departuresDict: Dictionary<String, [Departure]> = Dictionary<String, [Departure]>() {
        didSet {
            self.updateUI()
        }
    }
    var closestStation: Station? {
        didSet {
            self.updateUI()
        }
    }
    var fetchedDepartures: [Departure]?
    var locateStation: LocateStation = LocateStation()
    var locationManager: CLLocationManager! = CLLocationManager()
    // Helpers to keep state
    var typesOfRows: [String] = [String]()
    var groupFromIndex = Dictionary<Int, Int>()

    @IBOutlet weak var closestStationLabel: WKInterfaceLabel!
    @IBOutlet weak var tableView: WKInterfaceTable!

    // MARK: - Initilization
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        println("awaking - finally!")
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locateStation.delegate = self
    }
    
    // MARK: - Will activate
    override func willActivate() {
        super.willActivate()
        println("willActivate()")
        // Reset UI
        self.closestStation = nil
        self.departuresDict = Dictionary<String, [Departure]>() // This will updateUI()
        // Start updating location
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - Update UI
    func updateUI() {
        if 0 == self.departuresDict.count {
            println("updateUI() - missing departuresDict")
        } else if 0 == self.mappingDict.count {
            println("updateUI() - missing mappingDict")
        } else {
            println("updateUI() - has both")
        }
        if nil == self.closestStation {
            self.closestStationLabel.setText("Söker plats...")
            self.tableView.setNumberOfRows(0, withRowType: "header")
            return
        }
        
        self.closestStationLabel.setText(self.closestStation!.title)
        
        self.calculateTypesOfRows()
        self.tableView.setNumberOfRows(self.typesOfRows.count, withRowType: "header")
        self.tableView.setRowTypes(self.typesOfRows)
        self.fillTableWithContent()
    }
    
    func calculateTypesOfRows() {
        // Calculate type for the rows
        self.typesOfRows = [String]()
        self.groupFromIndex = Dictionary<Int, Int>()
        
        for (index, mappingName) in self.mappingDict {
            // TODO: Calculate startIndexGroup2 in dynamic way, and change variable name
            self.groupFromIndex[typesOfRows.count] = index

            self.typesOfRows.append("header")
            if let depList = self.departuresDict[mappingName] {
                for _ in 1...depList.count {
                    self.typesOfRows.append("details")
                }
            }
        }
    }
    
    func fillTableWithContent() {
        println("fillTableWithContent() -  InterfaceController")
        // Create table rows and fill with content
        var currentHeaderIndex: Int?
        var currentGroupIndex: Int?
        var currentGroupDepartures = [Departure]()
        for (index, rowType) in enumerate(self.typesOfRows) {
            if "header" == rowType {
                if let header = self.tableView.rowControllerAtIndex(index) as! TravelHeaderRow? {
                    // Set label for header row
                    currentHeaderIndex = index
                    currentGroupIndex = self.groupFromIndex[index]
                    if nil != currentGroupIndex {
                        if let mapName = self.mappingDict[currentGroupIndex!] {
                            var headerSuffix = ""
                            if let depGroup = self.departuresDict[mapName] {
                                currentGroupDepartures = depGroup
                                if let firstDeparture = depGroup.first {
                                    if firstDeparture.from_central_direction != nil {
                                        if firstDeparture.from_central_direction! == firstDeparture.direction {
                                            headerSuffix = "från T-centralen"
                                        } else {
                                            headerSuffix = "mot T-centralen"
                                        }
                                    }
                                }
                            }
                            
                            let directionLabel: String
                            let imageName: String
                            let textColor: UIColor
                            if mapName.rangeOfString("gröna") != nil {
                                imageName = "logo_green"
                                directionLabel = "Grön linje"
                                textColor = UIColor.greenColor()
                            } else if mapName.rangeOfString("röda") != nil {
                                imageName = "logo_red"
                                directionLabel = "Röd linje"
                                textColor = UIColor.redColor()
                            } else if mapName.rangeOfString("blå") != nil {
                                imageName = "logo_blue"
                                directionLabel = "Blå linje"
                                textColor = UIColor.blueColor()
                            } else {
                                imageName = "logo_green"
                                directionLabel = "Okänd linje"
                                textColor = UIColor.whiteColor()
                            }
                            header.headerLabel.setTextColor(textColor)
                            header.trainImage.setImage(UIImage(named: imageName))
                            if "" != headerSuffix {
                                header.headerLabel.setText(headerSuffix)
                            } else {
                                header.headerLabel.setText(directionLabel)
                            }
                        }
                    }
                }
            } else if "details" == rowType {
                if let detailRow = self.tableView.rowControllerAtIndex(index) as! TravelDetailsRow? {
                    // Set label for details row
                    var departure: Departure?
                    if nil != currentHeaderIndex {
                        let indexInGroup = index - currentHeaderIndex! - 1
                        if indexInGroup >= 0 && indexInGroup < currentGroupDepartures.count {
                            departure = currentGroupDepartures[indexInGroup]
                        }
                    }
                    if nil != departure {
                        detailRow.remainingTimeLabel.setText(departure!.remainingTime)
                        detailRow.destinationLabel.setText(departure!.destination)
                    }
                }
            }
        }
    }
    
    // MARK: - Locate station delegate protocol
    func locateStationFoundSortedStations(stationsSorted: [Station], withDepartures departures: [Departure]?, error: NSError?) {
        self.closestStation = stationsSorted.first
        if nil == departures {
            println("No departures were found. Error: \(error)")
        }
        self.fetchedDepartures = departures
        self.createMappingFromFetchedDepartures()
    }
    
    func createMappingFromFetchedDepartures() {
        if nil != self.fetchedDepartures && nil != self.closestStation {
            (self.mappingDict, self.departuresDict) = Utils.getMappingFromDepartures(self.fetchedDepartures!, station: self.closestStation!, mappingStart: 1)
        }
    }
    
    // MARK: - Refresh location
    @IBAction func refreshLocation() {
        self.closestStation = nil
        self.locationManager.startUpdatingLocation()
    }

    // MARK: - Get location of the user
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("didUpdateLocations")
        self.locationManager.stopUpdatingLocation()
        let location = locations.last as! CLLocation
        self.locateStation.findClosestStationFromLocationAndFetchDepartures(location)
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("ERROR - location manager. \(error)")
    }
}

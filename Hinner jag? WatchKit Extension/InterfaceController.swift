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

class InterfaceController: WKInterfaceController, CLLocationManagerDelegate {
    // MARK: - Variables
    var departuresDict: Dictionary<Int, [Departure]> = Dictionary<Int, [Departure]>() {
        didSet {
            self.updateUI()
        }
    }
    var closestStation: Station? {
        didSet {
            self.updateUI()
        }
    }
    var departures: [Departure]?
    var locateStation: LocateStation = LocateStation()
    var locationManager: CLLocationManager! = CLLocationManager()

    @IBOutlet weak var closestStationLabel: WKInterfaceLabel!
    @IBOutlet weak var tableView: WKInterfaceTable!

    // MARK: - Initilization
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        println("awaking - finally!")
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        
        // Set up callback
        self.locateStation.locationUpdatedCallback = { (stationsSorted: [Station], departures: [Departure]?, error: NSError?) in
            self.closestStation = stationsSorted.first
            if nil == departures {
                println("No departures were found. Error: \(error)")
            }
            self.departures = departures
            // Add departures into separated groups
            var tmpDict: Dictionary<Int, [Departure]> = Dictionary<Int, [Departure]>()
            for dept in departures! {
                if let depList = tmpDict[dept.direction] {
                    tmpDict[dept.direction]?.append(dept)
                } else {
                    tmpDict[dept.direction] = [Departure]()
                    tmpDict[dept.direction]?.append(dept)
                }
            }
            self.departuresDict = tmpDict
        }
    }
    
    // MARK: - Will activate
    override func willActivate() {
        super.willActivate()
        println("willActivate()")
        // Reset UI
        self.closestStation = nil
        self.departuresDict = Dictionary<Int, [Departure]>() // This will updateUI()
        // Start updating location
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - Update UI
    func updateUI() {
        println("updateUI()")
        if nil == self.closestStation {
            self.closestStationLabel.setText("Söker plats...")
            self.tableView.setNumberOfRows(0, withRowType: "header")
            return
        }
        
        self.closestStationLabel.setText(self.closestStation!.title)
        
        var (typesOfRows, startIndexGroup2) = self.calculateTypesOfRows()
        self.tableView.setNumberOfRows(typesOfRows.count, withRowType: "header")
        self.tableView.setRowTypes(typesOfRows)
        self.fillTableWithContent(typesOfRows, startIndexGroup2: startIndexGroup2)
    }
    
    func calculateTypesOfRows() -> ([String], Int) {
        // Calculate type for the rows
        var typesOfRows: [String] = [String]()
        if let group1 = self.departuresDict[1] {
            typesOfRows.append("header")
            var counter = 0
            for item in group1 {
                if counter < 2 {
                    typesOfRows.append("details")
                }
                counter++
            }
        }
        var startIndexGroup2 = typesOfRows.count
        if let group2 = self.departuresDict[2] {
            typesOfRows.append("header")
            var counter = 0
            for item in group2 {
                if counter < 2 {
                    typesOfRows.append("details")
                }
                counter++
            }
        }
        return (typesOfRows, startIndexGroup2)
    }
    
    func fillTableWithContent(typesOfRows: [String], startIndexGroup2: Int) {
        // Create table rows and fill with content
        for (index, rowType) in enumerate(typesOfRows) {
            if "header" == rowType {
                if let header = self.tableView.rowControllerAtIndex(index) as! TravelHeaderRow? {
                    if index < startIndexGroup2 {
                        header.headerLabel.setText("Plattform 1")
                    } else {
                        header.headerLabel.setText("Plattform 2")
                    }
                }
            } else if "details" == rowType {
                if let detailRow = self.tableView.rowControllerAtIndex(index) as! TravelDetailsRow? {
                    var departure: Departure?
                    if index < startIndexGroup2 {
                        if let group1 = self.departuresDict[1] {
                            let usedIndex = index - 1 // Start at first departure
                            if usedIndex < group1.count {
                                departure = group1[usedIndex]
                            }
                        }
                    } else {
                        if let group2 = self.departuresDict[2] {
                            let usedIndex = index - startIndexGroup2 - 1 // Start at first departure
                            if usedIndex >= 0 && usedIndex < group2.count {
                                departure = group2[usedIndex]
                            }
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

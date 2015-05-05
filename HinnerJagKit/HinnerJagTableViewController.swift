//
//  HinnerJagTableViewController.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 29/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit
import MapKit

public class HinnerJagTableViewController: UITableViewController, LocateStationDelegate
{
    // MARK: - Variables
    public var mappingDict: Dictionary <Int, String> = Dictionary <Int, String>()
    public var departuresDict: Dictionary<String, [Departure]> = Dictionary<String, [Departure]>() {
        didSet {
            self.updateUI()
        }
    }
    
    public var selectChosenStation: Bool = false {
        didSet {
            self.updateUI()
        }
    }

    public var closestStation: Station?
    public var closestSortedStations: [Station] = [Station]()
    
    // MARK: - Locate station
    public var locateStation: LocateStation = LocateStation()
    public func locateStationFoundSortedStations(stationsSorted: [Station], withDepartures departures: [Departure]?, error: NSError?) {
        let station = stationsSorted.first
        self.closestStation = station
        self.closestSortedStations = stationsSorted
        if nil != station {
            println("Now we are using the location callback. \(station!)")
            self.trackEvent("Station", action: "found", label: "\(station!.title) (\(station!.id))", value: 1)
        } else {
            self.trackEvent("Station", action: "not_found", label: "", value: nil)
        }
        
        if nil == departures {
            println("No departures were found. Error: \(error)")
            self.trackEvent("Departures", action: "not_found", label: "", value: nil)
            return
        }
        
        (self.mappingDict, self.departuresDict) = Utils.getMappingFromDepartures(departures!, mappingStart: 1)
        self.trackEvent("Departures", action: "found", label: "\(self.departuresDict.count) groups", value: 1)
    }

    // MARK: - Get last known location
    public func getLastLocation() -> CLLocation? {
        return nil
    }
    
    // MARK: - Toggle to choose different station
    public func changeChosenStation() {
        println("MainApp - changeChosenStation: \(self.selectChosenStation)")
        self.selectChosenStation = !self.selectChosenStation
    }
    
    
    // MARK: - Lifecycle stuff
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        self.gaSetup()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.locateStation.delegate = self
    }
    
    // MARK: - Update UI
    public func updateUI() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    
    // MARK: - Table stuff
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.departuresDict.count + 1 // Extra section for closest station
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let mappingName = self.mappingDict[section] {
            if let depList = self.departuresDict[mappingName] {
                return depList.count
            }
        }
        // For first section
        if self.selectChosenStation {
            return max(self.closestSortedStations.count - 1, 0)
        } else {
            return 0
        }
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section != 0 {
            return
        }
        let usedRow = indexPath.row + 1
        println("Did select section: \(indexPath.section) row: \(usedRow)")
        if usedRow < self.closestSortedStations.count {
            let station = self.closestSortedStations[usedRow]
            searchFromNewClosestStation(station)
            self.trackEvent("Station", action: "change_from_table", label: "\(station.title) (\(station.id))", value: 1)
        }
        self.selectChosenStation = false
    }
    
    public func searchFromNewClosestStation(newStation: Station) {
        self.closestStation = newStation
        println("Selected station: \(self.closestStation!)")
        self.locateStation.findClosestStationFromLocationAndFetchDepartures(self.closestStation!)
        self.departuresDict = Dictionary<String, [Departure]>()
    }
}

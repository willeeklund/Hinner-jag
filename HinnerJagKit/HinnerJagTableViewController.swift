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
import HinnerJagKit

public class HinnerJagTableViewController: UITableViewController, LocateStationDelegate
{
    // MARK: - Variables
    public var fetchedDepartures: [Departure]?
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

    public var closestStation: Site?
    public var closestSortedStations: [Site] = [Site]()
    
    // MARK: - Locate station
    public var locateStation: LocateStation = LocateStation()
    
    public func locateStationFoundClosestStation(station: Site?) {
        self.closestStation = station
    }
    
    public func locateStationFoundSortedStations(stationsSorted: [Site], withDepartures departures: [Departure]?, error: NSError?) {
        let station = stationsSorted.first
        self.closestSortedStations = stationsSorted
        self.fetchedDepartures = departures
        if nil != station {
            print("Now we are using the location callback. \(station!)")
            self.trackEvent("Station", action: "found", label: "\(station!.title) (\(station!.siteId))", value: 1)
        } else {
            self.trackEvent("Station", action: "not_found", label: "", value: nil)
        }
        
        if nil == departures {
            print("No departures were found. Error: \(error)")
            self.trackEvent("Departures", action: "not_found", label: "", value: nil)
            return
        }
        self.createMappingFromFetchedDepartures()
        self.trackEvent("Departures", action: "found", label: "\(self.departuresDict.count) groups", value: 1)
    }

    // MARK: - Get last known location
    public func getLastLocation() -> CLLocation? {
        return nil
    }
    
    // MARK: - Create mapping from fetched departures
    public func createMappingFromFetchedDepartures() {
        if nil != self.fetchedDepartures && nil != self.closestStation {
            (self.mappingDict, self.departuresDict) = Utils.getMappingFromDepartures(
                self.fetchedDepartures!,
                mappingStart: 1
            )
        }
    }
    
    // MARK: - Toggle to choose different station
    public func changeChosenStation() {
        self.selectChosenStation = !self.selectChosenStation
    }
    
    // MARK: - Select preferred travel type from a segment
    public func setPreferredTransportType(type: TransportType) {
        Utils.setPreferredTransportType(type)
        self.createMappingFromFetchedDepartures()
        self.trackEvent("TravelType", action: "changePreferred", label: "\(type)", value: 1)
        print("Preferred travel type \(type)")
    }
    
    // MARK: - Lifecycle stuff
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        self.gaSetup()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.locateStation.delegate = self
    }
    
    // MARK: - Update UI
    public func updateUI() {
        headlineCell?.stationTypeSegment.hidden = true
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    
    public func shouldShowStationTypeSegment() -> Bool {
        // If we do not have departures or we only have one type of departures,
        // do not show the segmented control
        if nil == fetchedDepartures {
            return false
        }
        let uniqueTransportTypes = Utils.uniqueTransportTypesFromDepartures(fetchedDepartures!)
        return uniqueTransportTypes.count > 1
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
        print("Did select section: \(indexPath.section) row: \(usedRow)")
        if usedRow < self.closestSortedStations.count {
            let station = self.closestSortedStations[usedRow]
            searchFromNewClosestStation(station)
            self.trackEvent("Station", action: "change_from_table", label: "\(station.title!) (\(station.siteId))", value: 1)
        }
        self.selectChosenStation = false
    }

    var headlineCell: HeadlineCell?
    override public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            headlineCell = HeadlineCell.createCellForTableView(
                tableView,
                controller: self,
                closestStation: self.closestStation,
                location: self.getLastLocation(),
                departures: fetchedDepartures
            )
            return headlineCell!
        } else {
            return TravelHeaderCell.createCellForIndexPath(
                section,
                tableView: tableView,
                mappingDict: self.mappingDict,
                departuresDict: self.departuresDict
            )
        }
    }
    
    public func searchFromNewClosestStation(newStation: Site) {
        self.closestStation = newStation
        print("Selected station: \(self.closestStation!)")
        // Instead of searching through the active stations to find the closest,
        // just trigger fetching departures for selected station
        self.locateStation.findDeparturesFromStation(newStation, stationList: nil)
        self.departuresDict = Dictionary<String, [Departure]>()
    }
}

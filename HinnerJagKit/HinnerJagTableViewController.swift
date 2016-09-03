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

open class HinnerJagTableViewController: UITableViewController, LocateStationDelegate
{
    // MARK: - Variables
    open var fetchedDepartures: [Departure]?
    open var mappingDict: Dictionary <Int, String> = Dictionary <Int, String>()
    open var departuresDict: Dictionary<String, [Departure]> = Dictionary<String, [Departure]>() {
        didSet {
            self.updateUI()
        }
    }
    
    open var selectChosenStation: Bool = false {
        didSet {
            self.updateUI()
        }
    }

    open var closestStation: Site?
    open var closestSortedStations: [Site] = [Site]()
    
    // MARK: - Locate station
    open var locateStation: LocateStation = LocateStation()
    
    open func locateStationFoundClosestStation(_ station: Site?) {
        self.closestStation = station
    }
    
    open func locateStationFoundSortedStations(_ stationsSorted: [Site], withDepartures departures: [Departure]?, error: NSError?) {
        let station = stationsSorted.first
        self.closestSortedStations = stationsSorted
        self.fetchedDepartures = departures
        if nil != station && nil != station!.title {
            self.trackEvent("Station", action: "found", label: "\(station!.title!) (\(station!.siteId))", value: 1)
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
    open func getLastLocation() -> CLLocation? {
        return nil
    }
    
    // MARK: - Create mapping from fetched departures
    open func createMappingFromFetchedDepartures() {
        if nil != self.fetchedDepartures && nil != self.closestStation {
            (self.mappingDict, self.departuresDict) = Utils.getMappingFromDepartures(
                self.fetchedDepartures!,
                mappingStart: 1
            )
        }
    }
    
    // MARK: - Toggle to choose different station
    open func changeChosenStation() {
        self.selectChosenStation = !self.selectChosenStation
    }
    
    // MARK: - Select preferred travel type from a segment
    open func setPreferredTransportType(_ type: TransportType) {
        Utils.setPreferredTransportType(type)
        self.createMappingFromFetchedDepartures()
        self.trackEvent("TravelType", action: "changePreferred", label: "\(type)", value: 1)
        print("Preferred travel type \(type)")
    }
    
    // MARK: - Lifecycle stuff
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.locateStation.delegate = self
    }
    
    // MARK: - Update UI
    open func updateUI() {
        headlineCell?.stationTypeSegment.isHidden = true
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    open func shouldShowStationTypeSegment() -> Bool {
        // If we do not have departures or we only have one type of departures,
        // do not show the segmented control
        if nil == fetchedDepartures {
            return false
        }
        let uniqueTransportTypes = Utils.uniqueTransportTypesFromDepartures(fetchedDepartures!)
        return uniqueTransportTypes.count > 1
    }
    
    // MARK: - Table stuff
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return self.departuresDict.count + 1 // Extra section for closest station
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section != 0 {
            return
        }
        let usedRow = (indexPath as NSIndexPath).row + 1
        print("Did select section: \((indexPath as NSIndexPath).section) row: \(usedRow)")
        if usedRow < self.closestSortedStations.count {
            let station = self.closestSortedStations[usedRow]
            searchFromNewClosestStation(station)
            self.trackEvent("Station", action: "change_from_table", label: "\(station.title!) (\(station.siteId))", value: 1)
        }
        self.selectChosenStation = false
    }

    var headlineCell: HeadlineCell?
    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
                controller: self,
                tableView: tableView,
                mappingDict: self.mappingDict,
                departuresDict: self.departuresDict
            )
        }
    }
    
    // MARK: - Search from new closest station
    open func searchFromNewClosestStation(_ newStation: Site) {
        self.closestStation = newStation
        print("Selected station: \(self.closestStation!)")
        // Instead of searching through the active stations to find the closest,
        // just trigger fetching departures for selected station
        self.locateStation.findDeparturesFromStation(newStation, stationList: nil)
        self.departuresDict = Dictionary<String, [Departure]>()
    }
}

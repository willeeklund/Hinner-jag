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

public class HinnerJagTableViewController: UITableViewController
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
    public var shownStationType: StationType = Utils.getPreferredTravelType() {
        didSet {
            self.updateUI()
        }
    }

    public var closestStation: Station?
    public var closestSortedStations: [Station] = [Station]()
    public var locateStation: LocateStation = LocateStation()
    
    public func getLastLocation() -> CLLocation? {
        return nil
    }
    
    // MARK: - Create mapping from fetched departures
    public func createMappingFromFetchedDepartures() {
        if nil != self.fetchedDepartures && nil != self.closestStation {
            (self.mappingDict, self.departuresDict) = Utils.getMappingFromDepartures(self.fetchedDepartures!, station: self.closestStation!, mappingStart: 1)
        }
    }
    
    // MARK: - Toggle to choose different station
    public func changeChosenStation() {
        self.selectChosenStation = !self.selectChosenStation
    }
    
    // MARK: - Select preferred travel type from a segment
    public func setPreferredTravelType(type: StationType) {
        Utils.setPreferredTravelType(type)
        self.shownStationType = type
        self.createMappingFromFetchedDepartures()
    }
    
    // MARK: - Lifecycle stuff
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        self.gaSetup()
    }
    
    // MARK: - Update UI
    public func updateUI() {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    
    public func shouldShowStationTypeSegment() -> Bool {
        return self.closestStation != nil && self.closestStation!.stationType == .MetroAndTrain
    }
    
    // MARK: - Table stuff
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.departuresDict.count + 1 // Extra section for closest station
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section != 0 {
            return
        }
        println("Did select section: \(indexPath.section) row: \(indexPath.row)")
        if indexPath.row < self.closestSortedStations.count {
            let station = self.closestSortedStations[indexPath.row]
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

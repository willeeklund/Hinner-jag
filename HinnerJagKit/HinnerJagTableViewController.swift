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
    public var locateStation: LocateStation = LocateStation()

    
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

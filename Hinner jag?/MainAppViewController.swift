//
//  MainAppViewController.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import HinnerJagKit

class MainAppViewController: UITableViewController
{
    // MARK: - Variables
    var mappingDict: Dictionary <Int, String> = Dictionary <Int, String>()
    var departuresDict: Dictionary<String, [Departure]> = Dictionary<String, [Departure]>() {
        didSet {
            self.tableView.reloadData()
            println("Now we have \(self.departuresDict.count) groups")
        }
    }

    var closestStation: Station?
    var locateStation: LocateStation = LocateStation()
    var realtimeDeparturesObj = RealtimeDepartures()
//    var sortDepartures = SortDepartures()
    
    // MARK: - Lifecycle stuff
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.gaSetup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreeName("MainAppViewController")
        self.departuresDict = Dictionary<String, [Departure]>()
        self.locateStation.locationUpdatedCallback = { (station: Station?, departures: [Departure]?, error: NSError?) in
            self.closestStation = station
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
            
            (self.mappingDict, self.departuresDict) = SortDepartures.getMappingFromDepartures(departures!, mappingStart: 1)
            self.trackEvent("Departures", action: "found", label: "\(self.departuresDict.count) groups", value: 1)
            dispatch_async(dispatch_get_main_queue(), {
                self.refreshControl!.endRefreshing()
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.refresh(nil)
    }
    
    @IBAction func refresh(sender: AnyObject?) {
        println("Refreshing position")
        self.locateStation.startUpdatingLocation()
    }
    
    // MARK: - Table stuff
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.departuresDict.count + 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let mappingName = self.mappingDict[section] {
            if let depList = self.departuresDict[mappingName] {
                return depList.count
            }
        }
        return 0
    }
    
    // Header for table
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let reuseId = "HeadlineCell"
            var cell = self.tableView.dequeueReusableCellWithIdentifier(reuseId) as? HeadlineCell
            if nil == cell {
                cell = HeadlineCell()
            }
            let headerText = "Närmast:"
            if nil == self.closestStation {
                cell?.closestStationLabel?.text = "Söker efter plats..."
            } else {
                let dist = Int(self.closestStation!.distanceFromLocation(self.locateStation.locationManager.location))
                cell?.closestStationLabel?.text = "Närmast: \(self.closestStation!.title) (\(dist)m)"
            }
            
            return cell! as HeadlineCell
        } else {
            return TravelHeaderCell.createCellForIndexPath(section, tableView: tableView, mappingDict: self.mappingDict, departuresDict: self.departuresDict)
        }
    }
    
    // Cell in table
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return TravelDetailsCell.createCellForIndexPath(indexPath, tableView: tableView, mappingDict: self.mappingDict, departuresDict: self.departuresDict)
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 95.0
        } else {
            return 45.0
        }
    }
}

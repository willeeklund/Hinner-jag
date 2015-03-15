//
//  ViewController.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import HinnerJagKit

class ViewController: UITableViewController
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.departuresDict = Dictionary<String, [Departure]>()
        self.locateStation.locationUpdatedCallback = { (station: Station?, departures: [Departure]?, error: NSError?) in
            self.closestStation = station
            println("Now we are using the location callback. \(station)")
            if nil == departures {
                println("No departures were found. Error: \(error)")
            }
            
            (self.mappingDict, self.departuresDict) = SortDepartures.getMappingFromDepartures(departures!, mappingStart: 1)
            dispatch_async(dispatch_get_main_queue(), {
                self.refreshControl!.endRefreshing()
            })
            
        }
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
                cell?.closestStationLabel?.text = headerText
            } else {
                cell?.closestStationLabel?.text = "\(headerText) \(self.closestStation!.title)"
            }
            return cell! as HeadlineCell
        } else {
            let reuseId = "TravelHeaderCell"
            var cell = self.tableView.dequeueReusableCellWithIdentifier(reuseId) as? TravelHeaderCell
            if nil == cell {
                cell = TravelHeaderCell()
            }
            cell?.headerLabel?.text = self.mappingDict[section]
            return cell! as TravelHeaderCell
        }
    }
    
    // Cell in table
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseId = "TravelDetailsCell"
        var cell: TravelDetailsCell? = self.tableView.dequeueReusableCellWithIdentifier(reuseId) as? TravelDetailsCell
        if nil == cell {
            cell = TravelDetailsCell()
        }
        if let mappingName = self.mappingDict[indexPath.section] {
            if let depList = self.departuresDict[mappingName] {
                if indexPath.row < depList.count {
                    let departure = depList[indexPath.row]
                    cell?.remainingTimeLabel?.text = departure.remainingTime
                    cell?.destinationLabel?.text = departure.destination
                }
            }
        }
        return cell! as TravelDetailsCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 95.0
        } else {
            return 45.0
        }
    }
}

//
//  TodayViewController.swift
//  Hinner jag widget
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import NotificationCenter
import HinnerJagKit
import CoreLocation

class TodayViewController: HinnerJagTableViewController, NCWidgetProviding, CLLocationManagerDelegate, UITableViewDelegate {
    // MARK: - Variables
    var locationManager: CLLocationManager! = CLLocationManager()
    var linkColor = UIColor(red: 8.0/255.0, green: 206.0/255.0, blue: 253.0/255.0, alpha: 1)
    
    // MARK: - Life cycle
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        // Init GA
        self.gaSetup()
    }
    
    // MARK: - Get location of the user
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.locationManager.stopUpdatingLocation()
        let location = locations.last as! CLLocation
        self.locateStation.findClosestStationFromLocationAndFetchDepartures(location)
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("ERROR - location manager. \(error)")
    }
    
    override func getLastLocation() -> CLLocation? {
        return self.locationManager.location
    }

    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreeName("TodayViewController")
        self.tableView.delegate = self
        
        // Reset
        self.departuresDict = Dictionary<String, [Departure]>()
        self.closestStation = nil
        self.updatePreferredContentSize()

        // Set up callback
        self.locateStation.locationUpdatedCallback = { (stationsSorted: [Station], departures: [Departure]?, error: NSError?) in
            let station = stationsSorted.first
            self.closestStation = station
            self.closestSortedStations = stationsSorted
            if nil != station {
                self.trackEvent("Station", action: "found", label: "\(station!.title) (\(station!.id))", value: 1)
            } else {
                self.trackEvent("Station", action: "not_found", label: "", value: nil)
            }
            
            if nil == departures {
                println("No departures were found. Error: \(error)")
                self.trackEvent("Departures", action: "not_found", label: "", value: nil)
                return
            }
            
            // Add departures into separated groups
            (self.mappingDict, self.departuresDict) = Utils.getMappingFromDepartures(departures!, mappingStart: 1)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.locationManager.startUpdatingLocation()
        if nil != self.locationManager.location {
            // Less than 5 minutes ago, use old location
            if -300.0 < self.locationManager.location.timestamp.timeIntervalSinceNow {
                let sortedStations = self.locateStation.findClosestStationFromLocation(self.locationManager.location)
                let oldStation = sortedStations.first
                self.closestStation = oldStation
                self.updateUI()
            }
        }
    }

    // MARK: - Update UI
    override func updateUI() {
        super.updateUI()
        dispatch_async(dispatch_get_main_queue(), {
            self.updatePreferredContentSize()
        })
    }
    
    func updatePreferredContentSize() {
        var height: CGFloat = 30.0
        let rowHeight = CGFloat(self.tableView(self.tableView, heightForHeaderInSection: 1))
        var i = 0;
        while i < self.numberOfSectionsInTableView(self.tableView) {
            height += rowHeight * CGFloat(self.tableView(self.tableView, numberOfRowsInSection: i) + 1)
            i++
        }
        self.preferredContentSize = CGSizeMake(0, height)
    }
        
    // MARK: - Table stuff
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let mappingName = self.mappingDict[section] {
            if let depList = self.departuresDict[mappingName] {
                if self.departuresDict.count > 4 {
                    // We only have room for the next two 
                    // departures at T-centralen
                    return min(2, depList.count)
                }
                return depList.count
            }
        }
        // For first section
        if self.selectChosenStation {
            return self.closestSortedStations.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if self.shouldShowStationTypeSegment() {
                return 60.0
            } else {
                return 27.0
            }
        }
        return 27.0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 30
        }
        return 24.0
    }
    
    // Header for table
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return HeadlineCell.createCellForTableView(
                tableView,
                controller: self,
                closestStation: self.closestStation,
                location: self.getLastLocation(),
                shouldShowStationTypeSegment: self.shouldShowStationTypeSegment(),
                shownStationType: self.shownStationType
            )
        } else {
            return TravelHeaderCell.createCellForIndexPath(section, tableView: tableView, mappingDict: self.mappingDict, departuresDict: self.departuresDict)
        }
    }
    
    // Cell in table
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // Section for changing closest station manually
            let reuseId = "chooseStation"
            var cell = tableView.dequeueReusableCellWithIdentifier(reuseId) as! UITableViewCell?
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: reuseId)
            }
            if indexPath.row < self.closestSortedStations.count {
                let station = self.closestSortedStations[indexPath.row]
                var dist = station.distanceFromLocation(self.locateStation.locationManager.location)
                let distFormat = Utils.distanceFormat(dist)
                cell?.textLabel?.text = "    \(station.title) (\(distFormat))"
                cell?.textLabel?.textColor = self.linkColor
                cell?.textLabel?.font = UIFont(name: "Arial", size: 18.0)
            }
            
            return cell! as UITableViewCell
        } else {
            return TravelDetailsCell.createCellForIndexPath(indexPath, tableView: tableView, mappingDict: self.mappingDict, departuresDict: self.departuresDict)
        }
    }
    
    // MARK: - Today widget specific stuff
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        completionHandler(NCUpdateResult.NewData)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
            return UIEdgeInsetsZero
    }
}

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

class TodayViewController: UITableViewController, NCWidgetProviding, CLLocationManagerDelegate, UITableViewDelegate {
    // MARK: - Variables
    var mappingDict: Dictionary <Int, String> = Dictionary <Int, String>()
    var departuresDict: Dictionary<String, [Departure]> = Dictionary<String, [Departure]>() {
        didSet {
            self.updateUI()
        }
    }
    var closestStation: Station?
    var departures: [Departure]?
    var locateStation: LocateStation = LocateStation()
    var locationManager: CLLocationManager! = CLLocationManager()
    
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
        let location = locations.last as CLLocation
        self.locateStation.findClosestStationFromLocationAndFetchDepartures(location)
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("ERROR - location manager. \(error)")
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
            
            self.departures = departures
            // Add departures into separated groups
            (self.mappingDict, self.departuresDict) = SortDepartures.getMappingFromDepartures(departures!, mappingStart: 1)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.locationManager.startUpdatingLocation()
        if nil != self.locationManager.location {
            // Less than 5 minutes ago, use old location
            if -300.0 < self.locationManager.location.timestamp.timeIntervalSinceNow {
                if let oldStation = self.locateStation.findClosestStationFromLocation(self.locationManager.location) {
                    println("OldStation = \(oldStation.title)")
                    self.closestStation = oldStation
                    self.updateUI()
                }
            }
        }
    }

    // MARK: - Update UI
    func updateUI() {
        println("updateUI()")
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
            self.updatePreferredContentSize()
        })
    }
    
    func updatePreferredContentSize() {
        var height: CGFloat = 30.0
        let rowHeight = CGFloat(self.tableView(self.tableView, heightForHeaderInSection: 1))
        var i = 1; // Start at second section
        while i < self.numberOfSectionsInTableView(self.tableView) {
            height += rowHeight * CGFloat(self.tableView(self.tableView, numberOfRowsInSection: i) + 1)
            i++
        }
        self.preferredContentSize = CGSizeMake(0, height)
    }
        
    // MARK: - Table stuff
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.departuresDict.count + 1 // Extra section for closest station
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // Only header for the closest station section
            return 0
        }
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
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 27.0
        
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 24.0
    }
    
    // Header for table
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let reuseId = "HeaderCell"
            var cell = self.tableView.dequeueReusableCellWithIdentifier(reuseId) as? UITableViewCell
            if nil == cell {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: reuseId)
            }
            if nil == self.closestStation {
                cell?.textLabel?.text = "Söker efter plats..."
            } else {
                let dist = Int(self.closestStation!.distanceFromLocation(self.locationManager.location))
                cell?.textLabel?.text = "Närmast: \(self.closestStation!.title) (\(dist)m)"
            }
            return cell! as UITableViewCell
        } else {
            return TravelHeaderCell.createCellForIndexPath(section, tableView: tableView, mappingDict: self.mappingDict, departuresDict: self.departuresDict)
        }
    }
    
    // Cell in table
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return TravelDetailsCell.createCellForIndexPath(indexPath, tableView: tableView, mappingDict: self.mappingDict, departuresDict: self.departuresDict)
    }
    
    // MARK: - Today widget specific stuff
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        completionHandler(NCUpdateResult.NewData)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
            return UIEdgeInsetsZero
    }
}

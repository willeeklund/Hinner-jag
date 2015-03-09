//
//  ViewController.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import HinnerJagKit
import MapKit

class ViewController: UITableViewController, CLLocationManagerDelegate {
    // MARK: - Variables
    var departuresDict: Dictionary<Int, [Departure]> = Dictionary<Int, [Departure]>() {
        didSet {
            self.tableView.reloadData()
            println("Now we have \(self.departuresDict.count) groups")
        }
    }
    var locationManager: CLLocationManager! = CLLocationManager()
    var closestStation: Station?
    var locateStation = LocateStation()
    var realtimeDeparturesObj = RealtimeDepartures()
    
    // MARK: - Lifecycle stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        println("viewDidLoad::startUpdatingLocation()")
    }
    
    // MARK: - Get location of the user
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.locationManager.stopUpdatingLocation()
        let location = locations.last as CLLocation
        println("didUpdateLocations() with \(location)")
        self.closestStation = self.locateStation.findStationClosestToLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude)
        self.fetchDepartures()
    }
    
    @IBAction func refresh(sender: AnyObject?) {
        println("Refreshing position")
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - Fetch departures
    func fetchDepartures() {
        println("fetchDepartures() running")
        if nil == self.closestStation {
            println("Have not found any closest station yet, hold on")
            return
        }
        let stationId = self.closestStation!.id
        self.departuresDict = Dictionary<Int, [Departure]>()
        self.realtimeDeparturesObj.departuresFromStationId(stationId) {
            (departures: [Departure]?, error: NSError?) -> () in
            if nil == departures {
                println("No departures were found. Error: \(error)")
            }
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
            dispatch_async(dispatch_get_main_queue(), {
                self.refreshControl!.endRefreshing()
            })
        }
    }
    
    // MARK: - Table stuff
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.departuresDict.count + 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let depList = self.departuresDict[section] {
            return depList.count
        } else {
            return 0
        }
    }
    
    // Header for table
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        println("Header section \(section)")
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
            cell?.headerLabel?.text = "Plattform \(section)"
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
        if let depList = self.departuresDict[indexPath.section] {
            if indexPath.row < depList.count {
                let departure = depList[indexPath.row]
                cell?.remainingTimeLabel?.text = departure.remainingTime
                cell?.destinationLabel?.text = departure.destination
            }
        }
        return cell! as TravelDetailsCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 75.0
        } else {
            return 45.0
        }
    }
}

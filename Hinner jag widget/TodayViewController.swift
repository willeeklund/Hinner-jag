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

class TodayViewController: UIViewController, NCWidgetProviding, CLLocationManagerDelegate {
    // MARK: - Variables
    var departuresDict: Dictionary<Int, [Departure]> = Dictionary<Int, [Departure]>() {
        didSet {
            self.updateUI()
        }
    }
    var closestStation: Station?
    var departures: [Departure]?
    var locateStation: LocateStation = LocateStation()
    var locationManager: CLLocationManager! = CLLocationManager()
    
    @IBOutlet var todayView: UIView!
    @IBOutlet weak var closestStationLabel: UILabel!
    @IBOutlet weak var time_1_1: UILabel!
    @IBOutlet weak var time_1_2: UILabel!
    @IBOutlet weak var time_1_3: UILabel!
    @IBOutlet weak var time_2_1: UILabel!
    @IBOutlet weak var time_2_2: UILabel!
    @IBOutlet weak var time_2_3: UILabel!
    @IBOutlet weak var station_1_1: UILabel!
    @IBOutlet weak var station_1_2: UILabel!
    @IBOutlet weak var station_1_3: UILabel!
    @IBOutlet weak var station_2_1: UILabel!
    @IBOutlet weak var station_2_2: UILabel!
    @IBOutlet weak var station_2_3: UILabel!
    
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
        
        // Reset
        self.departuresDict = Dictionary<Int, [Departure]>()
        self.closestStation = nil

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
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.locationManager.startUpdatingLocation()
        if nil != self.locationManager.location {
            // Less than 5 minutes ago, use old location
            if -300.0 < self.locationManager.location.timestamp.timeIntervalSinceNow {
                if let oldStation = self.locateStation.findClosestStationFromLocation(self.locationManager.location) {
                    println("## OldStation = \(oldStation.title)")
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
            if nil == self.closestStation {
                self.closestStationLabel.text = "Söker efter plats..."
            } else {
                self.closestStationLabel.text = "Närmaste station: \(self.closestStation!.title)"
            }
            self.updateLabelForSection(1, row: 1, timeLabel: self.time_1_1, stationLabel: self.station_1_1)
            self.updateLabelForSection(1, row: 2, timeLabel: self.time_1_2, stationLabel: self.station_1_2)
            self.updateLabelForSection(1, row: 3, timeLabel: self.time_1_3, stationLabel: self.station_1_3)
            self.updateLabelForSection(2, row: 1, timeLabel: self.time_2_1, stationLabel: self.station_2_1)
            self.updateLabelForSection(2, row: 2, timeLabel: self.time_2_2, stationLabel: self.station_2_2)
            self.updateLabelForSection(2, row: 3, timeLabel: self.time_2_3, stationLabel: self.station_2_3)
        })
    }
    
    func updateLabelForSection(section: Int, row readableRow: Int, timeLabel: UILabel, stationLabel: UILabel) {
        let row = readableRow - 1
        if let depList = self.departuresDict[section] {
            if row < depList.count {
                let departure = depList[row]
                timeLabel.text = departure.remainingTime
                stationLabel.text = departure.destination
                return
            }
        }
        timeLabel.text = "..."
        stationLabel.text = "..."
    }
    
    // MARK: - Today widget specific stuff
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        completionHandler(NCUpdateResult.NewData)
    }
    
//    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
//            return UIEdgeInsetsZero
//    }
}

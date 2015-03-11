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
    
    @IBOutlet weak var closestStationLabel: UILabel!
    @IBOutlet weak var time_1_1: UILabel!
    @IBOutlet weak var time_1_2: UILabel!
    @IBOutlet weak var time_2_1: UILabel!
    @IBOutlet weak var time_2_2: UILabel!
    @IBOutlet weak var station_1_1: UILabel!
    @IBOutlet weak var station_1_2: UILabel!
    @IBOutlet weak var station_2_1: UILabel!
    @IBOutlet weak var station_2_2: UILabel!
    
    // MARK: - Life cycle
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Get location of the user
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.locationManager.stopUpdatingLocation()
        let location = locations.last as CLLocation
        self.locateStation.findClosestStationFromLocation(location)
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("ERROR - location manager. \(error)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("Today VC: viewDidLoad")
        
        // Reset
        self.departuresDict = Dictionary<Int, [Departure]>()
        self.closestStation = nil

        // Set up callback
        self.locateStation.locationUpdatedCallback = { (station: Station?, departures: [Departure]?, error: NSError?) in
            self.closestStation = station
            if nil == departures {
                println("No departures were found. Error: \(error)")
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
        
        self.locationManager.startUpdatingLocation()
    }

    func updateUI() {
        println("updateUI()")
        dispatch_async(dispatch_get_main_queue(), {
            if nil == self.closestStation {
                self.closestStationLabel.text = "Söker efter plats..."
            } else {
                self.closestStationLabel.text = "Närmaste station: \(self.closestStation!.title)"
                self.updateLabelForSection(1, row: 1, timeLabel: self.time_1_1, stationLabel: self.station_1_1)
                self.updateLabelForSection(1, row: 2, timeLabel: self.time_1_2, stationLabel: self.station_1_2)
                self.updateLabelForSection(2, row: 1, timeLabel: self.time_2_1, stationLabel: self.station_2_1)
                self.updateLabelForSection(2, row: 2, timeLabel: self.time_2_2, stationLabel: self.station_2_2)
            }
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
        timeLabel.text = ""
        stationLabel.text = ""
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
//    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
//            return UIEdgeInsetsZero
//    }
}
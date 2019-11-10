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

class TodayViewController: HinnerJagTableViewController, NCWidgetProviding, CLLocationManagerDelegate {
    // MARK: - Variables
    var locationManager: CLLocationManager! = CLLocationManager()

    
    // MARK: - Views to explain to user to click "Show more"
    @IBOutlet weak var coverView: UIView!
    
    @IBOutlet weak var showMoreImage: UIImageView!
    
    @IBOutlet weak var arrowTopRight: UIImageView!
    

    // MARK: - Life cycle
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        // Init GA
        gaSetup()
    }
    
    // MARK: - Get location of the user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        let location = locations.last!
        self.locateStation.findClosestStationFromLocationAndFetchDepartures(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR - location manager. \(error)")
    }
    
    override func getLastLocation() -> CLLocation? {
        return self.locationManager.location
    }
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreenName("TodayViewController")
        self.tableView.delegate = self
        if #available(iOSApplicationExtension 10.0, *) {
            // This makes it possible to see the longer display mode
            extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
        self.view.backgroundColor = UIColor.darkGray
        // Reset
        self.departuresDict = Dictionary<String, [Departure]>()
        self.closestStation = nil
        // Content size
        self.updatePreferredContentSize()
        // Set up cover views
        coverView.isHidden = true
        coverView.frame = CGRect.zero
        coverView.layer.zPosition = 3
        showMoreImage.layer.cornerRadius = 3
        showMoreImage.clipsToBounds = true
        arrowTopRight.image = arrowTopRight.image?.withRenderingMode(.alwaysTemplate)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.locationManager.startUpdatingLocation()
        if let locationManagerLocation = self.locationManager.location {
            // Less than 2 minutes ago, use old location
            if -120.0 < locationManagerLocation.timestamp.timeIntervalSinceNow {
                let sortedStations = self.locateStation.findClosestStationFromLocation(locationManagerLocation)
                let oldStation = sortedStations.first
                self.closestStation = oldStation
                self.updateUI()
            }
        }
        // Check if user has used this today widget before
        checkHasUsedBefore()
        // Set random info message
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.notificationEventInfoMessage), object: nil, userInfo: [
            "random": true
        ])
    }

    // MARK: - Update UI
    override func updateUI() {
        super.updateUI()
        DispatchQueue.main.async(execute: {
            self.updatePreferredContentSize()
        })
        if #available(iOSApplicationExtension 10.0, *) {
            switch extensionContext!.widgetActiveDisplayMode {
            case .expanded:
                print("We are already in the expanded mode")
                coverView.frame = CGRect.zero
                coverView.isHidden = true
                break
            case .compact:
                print("This is the compact mode")
                coverView.frame = view.frame
                coverView.isHidden = false
                break
            }
        } else {
            print("Old iOS version. No widgetActiveDisplayMode")
        }
    }
    
    func updatePreferredContentSize() {
        var height: CGFloat = 80.0
        let rowHeight = CGFloat(self.tableView(self.tableView, heightForHeaderInSection: 1))
        var i = 0;
        while i < self.numberOfSections(in: self.tableView) {
            height += rowHeight * CGFloat(self.tableView(self.tableView, numberOfRowsInSection: i) + 1)
            i += 1
        }
        height = max(height, 480)
        self.preferredContentSize = CGSize(width: 0, height: height)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        preferredContentSize = maxSize
        updateUI()
    }
    
    // MARK: - Table stuff
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let mappingName = self.mappingDict[section] {
            if let depList = self.departuresDict[mappingName] {
                if self.departuresDict.count > 4 {
                    // We only have room for the next two
                    // departures at T-centralen
                    return min(2, depList.count)
                }
                // Otherwise show maximum 4 in each group
                return min(4, depList.count)
            }
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if self.shouldShowStationTypeSegment() {
                return 90.0
            } else {
                return 57.0
            }
        }
        return 27.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).section == 0 {
            return 30
        }
        return 24.0
    }
    
    // Cell in table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0 {
            // Section for changing closest station manually
            let reuseId = "chooseStation"
            var cell = tableView.dequeueReusableCell(withIdentifier: reuseId)
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: reuseId)
            }
            let usedRow = (indexPath as NSIndexPath).row + 1
            if usedRow < self.closestSortedStations.count {
                let station = self.closestSortedStations[usedRow]
                let dist = station.distanceFromLocation(self.locateStation.locationManager.location!)
                let distFormat = Utils.distanceFormat(dist)
                cell?.textLabel?.text = "    \(station.title!) (\(distFormat))"
                cell?.textLabel?.textColor = Constants.linkColor
                cell?.textLabel?.font = UIFont(name: "Arial", size: 18.0)
            }
            return cell! as UITableViewCell
        } else {
            return TravelDetailsCell.createCellForIndexPath(indexPath, tableView: tableView, mappingDict: self.mappingDict, departuresDict: self.departuresDict)
        }
    }
    
    // MARK: - Today widget specific stuff
    private func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
            return .zero
    }
    
    // MARK: - Check if first time using today widget
    func checkHasUsedBefore() {
        let hasSeenTodayWidgetKey = "hasSeenTodayWidget"
        if !UserDefaults.standard.bool(forKey: hasSeenTodayWidgetKey) {
            UserDefaults.standard.set(true, forKey: hasSeenTodayWidgetKey)
            self.trackEvent("TodayWidget", action: "show", label: "first time", value: 1)
            UserDefaults.standard.synchronize()
        }
    }
}

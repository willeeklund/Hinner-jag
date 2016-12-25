//
//  MainAppViewController.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import MapKit
import HinnerJagKit

class MainAppViewController: HinnerJagTableViewController, BWWalkthroughViewControllerDelegate
{
    override func getLastLocation() -> CLLocation? {
        return self.locateStation.locationManager.location
    }
    
    // MARK: - Lifecycle stuff
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gaSetup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreenName("MainAppViewController")
        self.departuresDict = Dictionary<String, [Departure]>()
        self.closestStation = nil
        self.startWalkthroughTimer()
        self.refresh(nil)
    }
    
    @IBAction func refresh(_ sender: AnyObject?) {
        print("Refreshing position")
        self.locateStation.startUpdatingLocation()
        // Update info label with random message
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.notificationEventInfoMessage), object: nil, userInfo: [
            "random": true
        ])

    }
    
    // MARK: - Locate station delegate protocol
    override func locateStationFoundSortedStations(_ stationsSorted: [Site], withDepartures departures: [Departure]?, error: NSError?) {
        super.locateStationFoundSortedStations(stationsSorted, withDepartures: departures, error: error)
        DispatchQueue.main.async(execute: {
            self.refreshControl!.endRefreshing()
        })
    }
    
    // MARK: - Table stuff
    
    // Cell in table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0 {
            // Section for changing closest station manually
            let reuseId = "chooseStation"
            var cell = tableView.dequeueReusableCell(withIdentifier: reuseId)
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: reuseId)
            }
            let usedRow = (indexPath as NSIndexPath).row + 1
            if usedRow < self.closestSortedStations.count {
                let station = self.closestSortedStations[usedRow]
                if let location = self.locateStation.locationManager.location {
                    let dist = station.distanceFromLocation(location)
                    let distFormat = Utils.distanceFormat(dist)
                    cell?.textLabel?.text = "    \(station.title!) (\(distFormat))"
                }
                cell?.textLabel?.textColor = UIColor(red: 0, green: 0.478431, blue: 1.0, alpha: 1.0)
            }
            
            return cell! as UITableViewCell
        } else {
            // Travel details
            return TravelDetailsCell.createCellForIndexPath(indexPath, tableView: tableView, mappingDict: self.mappingDict, departuresDict: self.departuresDict)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if self.shouldShowStationTypeSegment() {
                return 160.0
            } else {
                return 120.0
            }
        } else {
            return 45.0
        }
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is MapViewController {
            let mapVC: MapViewController = segue.destination as! MapViewController
            mapVC.chosenStation = self.closestStation
            // If segue performed by code specifying line number to show
            if let dict = sender as? Dictionary<String, AnyObject> {
                if let lineNumber = dict["lineNumber"] as? Int {
                    mapVC.chosenLineNumber = lineNumber
                }
                if let chosenStopAreaTypeCode = dict["stopAreaTypeCode"] as? String {
                    mapVC.chosenStopAreaTypeCode = chosenStopAreaTypeCode
                }
            }
        }
    }
    
    // MARK: - Introduction walkthrough of the app
    func startWalkthroughTimer() {
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(MainAppViewController.checkIfHasSeenWalkthrough), userInfo: nil, repeats: false)
    }
    
    func checkIfHasSeenWalkthrough() {
        let walkthroughKey = "hasSeenWalkthrough2"
        if !UserDefaults.standard.bool(forKey: walkthroughKey) {
            self.showWalkthrough()
            UserDefaults.standard.set(true, forKey: walkthroughKey)
            self.trackEvent("Walkthrough", action: "show", label: "first time", value: 1)
            UserDefaults.standard.synchronize()
        }
    }
    
    @IBAction func showWalkthroughButtonPressed(_ sender: AnyObject) {
        self.showWalkthrough()
        self.trackEvent("Walkthrough", action: "show", label: "manual", value: 1)
    }

    var introVideoVC: BWWalkThroughVideoViewController?
    var walkthrough: BWWalkthroughViewController?
    func showWalkthrough() {
        let stb = UIStoryboard(name: "Main", bundle: Bundle(for: self.classForCoder))
        // Create walkthrough view controller
        walkthrough = stb.instantiateViewController(withIdentifier: "walk0") as? BWWalkthroughViewController
        if nil == walkthrough {
            print("Coulr not create walkthrough view controller")
            return
        }
        let page_one = stb.instantiateViewController(withIdentifier: "walk1")
        let page_two = stb.instantiateViewController(withIdentifier: "walk2")
        if page_two is BWWalkThroughVideoViewController {
            introVideoVC = page_two as? BWWalkThroughVideoViewController
        }
        // Attach the pages to the walkthrough master
        walkthrough!.delegate = self
        walkthrough!.addViewController(page_one)
        walkthrough!.addViewController(page_two)
        walkthrough!.view.backgroundColor = UIColor(hex: "F1FFF1")
        // Show the walkthrough view controller
        self.present(walkthrough!, animated: true) {
            print("Done presenting the walkthrough controller")
        }
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: nil)
        introVideoVC = nil
        walkthrough = nil
    }
    
    func walkthroughNextButtonPressed() {
        print("The next button was pressed")
    }
    
    func walkthroughPageDidChange(_ pageNumber:Int) {
        if 1 == pageNumber {
            introVideoVC?.playMovie()
            walkthrough?.closeButton?.setTitle("Klar med intro - använd appen", for: UIControlState())
        } else {
            walkthrough?.closeButton?.setTitle("Se introfilmen", for: UIControlState())
        }
    }
    
    // MARK: - Network activity indicator
    override open func setNetworkActivityIndicator(visible: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = visible
    }
}

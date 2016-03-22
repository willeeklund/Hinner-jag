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
        self.gaSetup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreenName("MainAppViewController")
        self.departuresDict = Dictionary<String, [Departure]>()
        self.closestStation = nil
        self.startWalkthroughTimer()
        self.refresh(nil)
    }
    
    @IBAction func refresh(sender: AnyObject?) {
        print("Refreshing position")
        self.locateStation.startUpdatingLocation()
    }
    
    // MARK: - Locate station delegate protocol
    override func locateStationFoundSortedStations(stationsSorted: [Station], withDepartures departures: [Departure]?, error: NSError?) {
        super.locateStationFoundSortedStations(stationsSorted, withDepartures: departures, error: error)
        dispatch_async(dispatch_get_main_queue(), {
            self.refreshControl!.endRefreshing()
        })
    }
    
    // MARK: - Table stuff
    
    // Cell in table
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // Section for changing closest station manually
            let reuseId = "chooseStation"
            var cell = tableView.dequeueReusableCellWithIdentifier(reuseId)
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: reuseId)
            }
            let usedRow = indexPath.row + 1
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
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if self.shouldShowStationTypeSegment() {
                return 130.0
            } else {
                return 90.0
            }
        } else {
            return 45.0
        }
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is MapViewController {
            let mapVC: MapViewController = segue.destinationViewController as! MapViewController
            mapVC.locateStation = self.locateStation
            mapVC.chosenStation = self.closestStation
        }
    }
    
    // MARK: - Introduction walkthrough of the app
    func startWalkthroughTimer() {
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(MainAppViewController.checkIfHasSeenWalkthrough), userInfo: nil, repeats: false)
    }
    
    func checkIfHasSeenWalkthrough() {
        let walkthroughKey = "hasSeenWalkthrough1"
        if !NSUserDefaults.standardUserDefaults().boolForKey(walkthroughKey) {
            self.showWalkthrough()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: walkthroughKey)
            self.trackEvent("Walkthrough", action: "show", label: "first time", value: 1)
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func showWalkthroughButtonPressed(sender: AnyObject) {
        self.showWalkthrough()
        self.trackEvent("Walkthrough", action: "show", label: "manual", value: 1)
    }
    
    func showWalkthrough() {
        let stb = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.classForCoder))
        // Create walkthrough view controller
        let walkthrough = stb.instantiateViewControllerWithIdentifier("walk0") as! BWWalkthroughViewController
        let page_one    = stb.instantiateViewControllerWithIdentifier("walk1")
        let page_two    = stb.instantiateViewControllerWithIdentifier("walk2")
        let page_three  = stb.instantiateViewControllerWithIdentifier("walk3")
        let page_four   = stb.instantiateViewControllerWithIdentifier("walk4")
        let page_five   = stb.instantiateViewControllerWithIdentifier("walk5")
        // Attach the pages to the walkthrough master
        walkthrough.delegate = self
        walkthrough.addViewController(page_one)
        walkthrough.addViewController(page_two)
        walkthrough.addViewController(page_three)
        walkthrough.addViewController(page_four)
        walkthrough.addViewController(page_five)
        // Show the walkthrough view controller
        self.presentViewController(walkthrough, animated: true, completion: nil)
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

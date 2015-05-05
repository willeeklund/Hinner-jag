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
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.gaSetup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreeName("MainAppViewController")
        self.departuresDict = Dictionary<String, [Departure]>()
        self.closestStation = nil
        self.startWalkthroughTimer()
        self.refresh(nil)
    }
    
    @IBAction func refresh(sender: AnyObject?) {
        println("Refreshing position")
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
    
    // Header for table
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let reuseId = "HeadlineCell"
            var cell = self.tableView.dequeueReusableCellWithIdentifier(reuseId) as? HeadlineCell
            if nil == cell {
                cell = HeadlineCell()
            }
            // Text on button
            let closestStationLabel = Utils.getLabelTextForClosestStation(self.closestStation, ownLocation: self.getLastLocation())
            cell?.closestStationButton.setTitle(closestStationLabel, forState: .Normal)
            
            cell?.controller = self
            return cell! as HeadlineCell
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
            let usedRow = indexPath.row + 1
            if usedRow < self.closestSortedStations.count {
                let station = self.closestSortedStations[usedRow]
                var dist = station.distanceFromLocation(self.locateStation.locationManager.location)
                let distFormat = Utils.distanceFormat(dist)
                cell?.textLabel?.text = "\(station.title) (\(distFormat))"
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
            return 95.0
        } else {
            return 45.0
        }
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is MapViewController {
            var mapVC: MapViewController = segue.destinationViewController as! MapViewController
            mapVC.locateStation = self.locateStation
            mapVC.chosenStation = self.closestStation
        }
    }
    
    // MARK: - Introduction walkthrough of the app
    func startWalkthroughTimer() {
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "checkIfHasSeenWalkthrough", userInfo: nil, repeats: false)
    }
    
    func checkIfHasSeenWalkthrough() {
        let walkthroughKey = "hasSeenWalkthrough1"
        if !NSUserDefaults.standardUserDefaults().boolForKey(walkthroughKey) {
            self.showWalkthrough()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: walkthroughKey)
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func showWalkthroughButtonPressed(sender: AnyObject) {
        self.showWalkthrough()
    }
    
    func showWalkthrough() {
        let stb = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.classForCoder))
        // Create walkthrough view controller
        let walkthrough = stb.instantiateViewControllerWithIdentifier("walk0") as! BWWalkthroughViewController
        let page_one = stb.instantiateViewControllerWithIdentifier("walk1") as! UIViewController
        let page_two = stb.instantiateViewControllerWithIdentifier("walk2") as! UIViewController
        let page_three = stb.instantiateViewControllerWithIdentifier("walk3") as! UIViewController
        let page_four = stb.instantiateViewControllerWithIdentifier("walk4") as! UIViewController
        let page_five = stb.instantiateViewControllerWithIdentifier("walk5") as! UIViewController
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

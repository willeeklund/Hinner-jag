//
//  InterfaceController.swift
//  HinnerJagWatchOS2 Extension
//
//  Created by Wilhelm Eklund on 27/08/15.
//  Copyright © 2015 Wilhelm Eklund. All rights reserved.
//

import WatchKit
import Foundation
import HinnerJagWatchKit

class InterfaceController: WKInterfaceController, CLLocationManagerDelegate, LocateStationDelegate {
    // MARK: - Variables
    var mappingDict: Dictionary <Int, String> = Dictionary <Int, String>()
    var departuresDict: Dictionary<String, [Departure]> = Dictionary<String, [Departure]>() {
        didSet {
            self.updateUI()
        }
    }
    var closestStation: Station? {
        didSet {
            self.updateUI()
        }
    }
    var fetchedDepartures: [Departure]?
    var locateStation: LocateStation = LocateStation()
    var locationManager: CLLocationManager! = CLLocationManager()
    // Helpers to keep state
    var typesOfRows: [String] = [String]()
    var groupFromIndex = Dictionary<Int, Int>()
    // Save away latest position in UserDefaults
    let latestStationLatKey = "latestStationLat"
    let latestStationLongKey = "latestStationLong"
    
    @IBOutlet weak var closestStationLabel: WKInterfaceLabel!
    @IBOutlet weak var tableView: WKInterfaceTable!
    
    // MARK: - Initilization
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        print("awaking - finally!")
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locateStation.delegate = self
        // Init GA
        self.gaSetup()
    }
    
    // MARK: - Will activate
    override func willActivate() {
        super.willActivate()
        print("willActivate()")
//        // Read latest station coordinates from UserDefaults
//        let latestStationLat = NSUserDefaults.standardUserDefaults().doubleForKey(latestStationLatKey)
//        let latestStationLong = NSUserDefaults.standardUserDefaults().doubleForKey(latestStationLongKey)
//        if 0.0 != latestStationLat && 0.0 != latestStationLong {
//            let location = CLLocation(latitude: latestStationLat, longitude: latestStationLong)
//            print("Latest location was \(location)")
//            self.locateStation.findClosestStationFromLocationAndFetchDepartures(location)
//        }
        // Reset UI
        self.departuresDict = Dictionary<String, [Departure]>() // This will updateUI()
        // Start updating location
        self.locationManager.requestLocation()
        
        self.setGAScreenName()
    }
    
    // MARK: - Update UI
    func updateUI() {
        if nil == self.closestStation {
            self.closestStationLabel.setText("Söker plats...")
            self.tableView.setNumberOfRows(0, withRowType: "header")
            return
        }
        
        self.closestStationLabel.setText(self.closestStation!.title)
        
        self.calculateTypesOfRows()
        self.tableView.setNumberOfRows(self.typesOfRows.count, withRowType: "header")
        self.tableView.setRowTypes(self.typesOfRows)
        self.fillTableWithContent()
    }
    
    func calculateTypesOfRows() {
        // Calculate type for the rows
        self.typesOfRows = [String]()
        self.groupFromIndex = Dictionary<Int, Int>()
        
        for (index, mappingName) in self.mappingDict {
            // TODO: Calculate startIndexGroup2 in dynamic way, and change variable name
            self.groupFromIndex[typesOfRows.count] = index
            
            self.typesOfRows.append("header")
            if let depList = self.departuresDict[mappingName] {
                for _ in 1...depList.count {
                    self.typesOfRows.append("details")
                }
            }
        }
    }
    
    func fillTableWithContent() {
        print("fillTableWithContent() -  InterfaceController")
        // Create table rows and fill with content
        var currentHeaderIndex: Int?
        var currentGroupIndex: Int?
        var currentGroupDepartures = [Departure]()
        for (index, rowType) in self.typesOfRows.enumerate() {
            if "header" == rowType {
                if let header = self.tableView.rowControllerAtIndex(index) as! TravelHeaderRow? {
                    // Set label for header row
                    currentHeaderIndex = index
                    currentGroupIndex = self.groupFromIndex[index]
                    if nil != currentGroupIndex {
                        if let mapName = self.mappingDict[currentGroupIndex!] {
                            var headerSuffix = ""
                            if let depGroup = self.departuresDict[mapName] {
                                currentGroupDepartures = depGroup
                                if let firstDeparture = depGroup.first {
                                    if firstDeparture.from_central_direction != nil {
                                        if firstDeparture.from_central_direction! == firstDeparture.direction {
                                            headerSuffix = "från T-centralen"
                                        } else {
                                            headerSuffix = "mot T-centralen"
                                        }
                                    }
                                }
                            }
                            
                            let directionLabel: String
                            let imageName: String
                            let textColor: UIColor
                            if mapName.rangeOfString("gröna") != nil {
                                imageName = "logo_green"
                                directionLabel = "Grön linje"
                                textColor = UIColor.greenColor()
                            } else if mapName.rangeOfString("röda") != nil {
                                imageName = "logo_red"
                                directionLabel = "Röd linje"
                                textColor = UIColor.redColor()
                            } else if mapName.rangeOfString("blå") != nil {
                                imageName = "logo_blue"
                                directionLabel = "Blå linje"
                                textColor = UIColor.blueColor()
                            } else {
                                imageName = "logo_green"
                                directionLabel = "Okänd linje"
                                textColor = UIColor.whiteColor()
                            }
                            header.headerLabel.setTextColor(textColor)
                            header.trainImage.setImage(UIImage(named: imageName))
                            if "" != headerSuffix {
                                header.headerLabel.setText(headerSuffix)
                            } else {
                                header.headerLabel.setText(directionLabel)
                            }
                        }
                    }
                }
            } else if "details" == rowType {
                if let detailRow = self.tableView.rowControllerAtIndex(index) as! TravelDetailsRow? {
                    // Set label for details row
                    var departure: Departure?
                    if nil != currentHeaderIndex {
                        let indexInGroup = index - currentHeaderIndex! - 1
                        if indexInGroup >= 0 && indexInGroup < currentGroupDepartures.count {
                            departure = currentGroupDepartures[indexInGroup]
                        }
                    }
                    if nil != departure {
                        detailRow.remainingTimeLabel.setText(departure!.remainingTime)
                        detailRow.destinationLabel.setText(departure!.destination)
                    }
                }
            }
        }
    }
    
    // MARK: - Locate station delegate protocol
    func locateStationFoundSortedStations(stationsSorted: [Station], withDepartures departures: [Departure]?, error: NSError?) {
        self.closestStation = stationsSorted.first
        if nil == departures {
            print("No departures were found. Error: \(error)")
        }
        self.fetchedDepartures = departures
        self.createMappingFromFetchedDepartures()
    }
    
    func createMappingFromFetchedDepartures() {
        if nil != self.fetchedDepartures && nil != self.closestStation {
            (self.mappingDict, self.departuresDict) = Utils.getMappingFromDepartures(self.fetchedDepartures!, station: self.closestStation!, mappingStart: 1)
        }
    }
    
    // MARK: - Refresh location
    @IBAction func refreshLocation() {
        print("refreshLocation()")
        self.closestStation = nil
        self.locationManager.requestLocation()
    }
    
    // MARK: - Get location of the user
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations")
        self.locationManager.stopUpdatingLocation()
        let location = locations.last!
        print("location = \(location)")
        self.locateStation.findClosestStationFromLocationAndFetchDepartures(location)
        // Save latest coordinates
        NSUserDefaults.standardUserDefaults().setDouble(location.coordinate.latitude, forKey: latestStationLatKey)
        NSUserDefaults.standardUserDefaults().setDouble(location.coordinate.longitude, forKey: latestStationLongKey)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("ERROR - location manager. \(error)")
    }
    
    // MARK: - Google Analytics
    func setGAScreenName() {
        self.setScreeName("WatchAppInterfaceController")
    }
    
    func gaSetup() {
//        let tracker = GAI.sharedInstance().defaultTracker
//        if tracker != nil {
//            print("Have already initialized tracker")
//            return
//        }
//        let hinnerJagKitBundle = NSBundle(forClass: LocateStation.classForCoder())
//        if let path = hinnerJagKitBundle.pathForResource("Info", ofType: "plist") {
//            if let infoDict = NSDictionary(contentsOfFile: path) as? Dictionary<String, AnyObject> {
//                if let gaTrackerId: String = infoDict["GA_TRACKING_ID"] as? String {
//                    if gaTrackerId.hasPrefix("UA-") {
//                        GAI.sharedInstance().trackUncaughtExceptions = true
//                        GAI.sharedInstance().trackerWithTrackingId(gaTrackerId)
//                    }
//                }
//            }
//        }
    }
    
    func setScreeName(name: String) {
//        let tracker = GAI.sharedInstance().defaultTracker
//        if nil == tracker {
//            return
//        }
//        tracker.set(kGAIScreenName, value: name)
//        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject])
    }
    
    func trackEvent(category: String, action: String, label: String, value: NSNumber?) {
//        let tracker = GAI.sharedInstance().defaultTracker
//        if nil == tracker {
//            return
//        }
//        let trackDictionary = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value).build()
//        tracker.send(trackDictionary as [NSObject : AnyObject])
    }
}

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
import WatchConnectivity

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
    @IBOutlet var fetchingDataLabel: WKInterfaceLabel!
    @IBOutlet var transportTypePicker: WKInterfacePicker!
    
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
        // Reset UI
        self.departuresDict = Dictionary<String, [Departure]>() // This will updateUI()
        // Start updating location
        self.locationManager.requestLocation()
        
        self.setGAScreenName()
    }
    
    // MARK: - Update UI
    func updateUI() {
        if nil == self.closestStation {
            self.intervalCheckForStation()
            return
        }
        
        self.closestStationLabel.setText(self.closestStation!.title)

        self.searchingForLocationTimer?.invalidate()
        self.searchingForLocationTimer = nil
        print("Stop station interval now, we have the station")
        
        self.calculateTypesOfRows()
        self.tableView.setNumberOfRows(self.typesOfRows.count, withRowType: "header")
        self.tableView.setRowTypes(self.typesOfRows)
        self.fillTableWithContent()
        self.intervalCheckForDepartures()
        self.setupTransportTypePicker()
    }
    
    /**
    Calculate type for the rows
     
    Using the class properties mappingDict and departuresDict we can generate a list
    describing which type of rows should be shown in our table
    */
    func calculateTypesOfRows() {
        self.typesOfRows = [String]()
        self.groupFromIndex = Dictionary<Int, Int>()
        
        for (index, mappingName) in self.mappingDict {
            self.groupFromIndex[typesOfRows.count] = index
            if let depList = self.departuresDict[mappingName] {
                if depList.count > 0 {
                    // Only add the header if we have departures in the list
                    self.typesOfRows.append("header")
                }
                for _ in 1...depList.count {
                    self.typesOfRows.append("details")
                }
            }
        }
    }
    
    /** 
    Create table rows and fill with content
     
    This is based on the list typesOfRows calculated previously
    */
    func fillTableWithContent() {
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
                            if let depGroup = self.departuresDict[mapName] {
                                currentGroupDepartures = depGroup
                            }
                            // Use Departure class methods to calculate the header label look
                            let headerSuffix = Departure.createDirectionSuffix(mapName, departuresDict: self.departuresDict)
                            let (directionLabel, imageName, textColor) = Departure.createLabelAndImageNameFromSection(mapName, departuresDict: self.departuresDict)
                            // Header label
                            header.headerLabel.setTextColor(textColor)
                            if "" != headerSuffix {
                                header.headerLabel.setText(headerSuffix)
                            } else {
                                header.headerLabel.setText(directionLabel)
                            }
                            // Image
                            if nil != imageName {
                                header.trainImage.setImage(UIImage(named: imageName!))
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
    
    // MARK: - Select transport type
    var uniqueTransportTypes = [TransportType]()
    func setupTransportTypePicker() {
        if nil == fetchedDepartures {
            transportTypePicker.setHidden(true)
            return
        }
        uniqueTransportTypes = Utils.uniqueTransportTypesFromDepartures(fetchedDepartures!)
        let currentTransportType = Utils.currentTransportType(fetchedDepartures!)
        var selectedIndex = 0
        var pickerItems = [WKPickerItem]()
        for (index, type) in uniqueTransportTypes.enumerate() {
            let item = WKPickerItem()
            item.title = Utils.transportTypeStringToName(type)
            pickerItems.append(item)
            if type == currentTransportType {
                selectedIndex = index
            }
        }
        transportTypePicker.setItems(pickerItems)
        transportTypePicker.setSelectedItemIndex(selectedIndex)
        transportTypePicker.setHidden(false)
    }
    
    @IBAction func didChangeTransportType(index: Int) {
        let newType = uniqueTransportTypes[index]
        Utils.setPreferredTransportType(newType)
        createMappingFromFetchedDepartures()
    }
    
    // MARK: - Timers to indicate time for user with dots
    var searchingForLocationTimer: NSTimer?
    var searchingForDeparturesTimer: NSTimer?
    
    func intervalCheckForStation() {
        let fetchingLocationText = "Söker plats"
        self.closestStationLabel.setText(fetchingLocationText)
        self.tableView.setNumberOfRows(0, withRowType: "header")
        // We are not fetching data until we have found our location
        self.fetchingDataLabel.setHidden(true)
        // Interval to see when we find the station
        var timerStationCount = 0
        self.searchingForLocationTimer = NSTimer.schedule(repeatInterval: 1) { (timer) in
            // Only keep one timer instance going
            if timer != self.searchingForLocationTimer {
                // If not the same timer, remove it
                timer.invalidate()
                return
            }
            timerStationCount += 1
            // Check if still no station is selected
            if nil == self.closestStation {
                let dots = String(count: timerStationCount, repeatedValue: "." as Character)
                self.closestStationLabel.setText("\(fetchingLocationText)\(dots)")
            } else {
                self.searchingForLocationTimer?.invalidate()
                self.searchingForLocationTimer = nil
                print("Stopped station interval after \(timerStationCount) seconds")
            }
        }
    }
    
    func intervalCheckForDepartures() {
        // If we have not fetched departures, count to 10 dots
        if nil == self.fetchedDepartures {
            // If we found any details about departures,
            // hide "Loading data" label
            let fetchingDataText = "Hämtar avgångar från \(self.closestStation!.title!)"
            self.fetchingDataLabel.setText(fetchingDataText)
            self.fetchingDataLabel.setHidden(false)
            // Interval to see when we find the departures
            var timerDeparturesCount = 0
            self.searchingForDeparturesTimer = NSTimer.schedule(repeatInterval: 1) { (timer) in
                // Keep single timer
                if timer != self.searchingForDeparturesTimer {
                    // If not the same timer, remove it
                    print("Illegal timer -> invalidate")
                    timer.invalidate()
                    return
                }
                timerDeparturesCount += 1
                // Check if still no station is selected
                if timerDeparturesCount < 10 {
                    let points = String(count: timerDeparturesCount, repeatedValue: "." as Character)
                    self.fetchingDataLabel.setText("\(fetchingDataText)\(points)")
                } else {
                    self.searchingForDeparturesTimer?.invalidate()
                    self.searchingForDeparturesTimer = nil
                    print("Stopped departures interval after \(timerDeparturesCount) seconds")
                }
            }
        } else {
            print("Now we have fetched departures from SL")
            // We have the result from SL, stop counting dots
            self.searchingForDeparturesTimer?.invalidate()
            self.searchingForDeparturesTimer = nil
            
            if self.fetchedDepartures?.count > 0 {
                // We have departures, hide info label
                self.fetchingDataLabel.setHidden(true)
            } else {
                // We have the info from SL but it does not contain any departures
                self.fetchingDataLabel.setText("SL har inte realtidsinfo om några avgångar från \(self.closestStation!.title!) för tillfället.")
            }
        }
    }
    
    // MARK: - Locate station delegate protocol
    func locateStationFoundClosestStation(station: Station?) {
        self.fetchedDepartures = nil
        self.closestStation = station
        self.departuresDict = Dictionary<String, [Departure]>()
    }
    
    func locateStationFoundSortedStations(stationsSorted: [Station], withDepartures departures: [Departure]?, error: NSError?) {
        if nil == departures {
            print("No departures were found. Error: \(error)")
        }
        self.fetchedDepartures = departures
        self.createMappingFromFetchedDepartures()
    }
    
    func createMappingFromFetchedDepartures() {
        if nil != self.fetchedDepartures && nil != self.closestStation {
            (self.mappingDict, self.departuresDict) = Utils.getMappingFromDepartures(
                self.fetchedDepartures!,
                mappingStart: 1
            )
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
        // Do not restart the location-finder again if we are already fetching data from server
        if nil == self.searchingForDeparturesTimer {
            self.locateStation.findClosestStationFromLocationAndFetchDepartures(location)
        } else {
            print("Ignoring double location fetching")
        }
        // Save latest coordinates
        NSUserDefaults.standardUserDefaults().setDouble(location.coordinate.latitude, forKey: latestStationLatKey)
        NSUserDefaults.standardUserDefaults().setDouble(location.coordinate.longitude, forKey: latestStationLongKey)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("ERROR - location manager. \(error)")
    }
    
    // MARK: - Google Analytics
    func setGAScreenName() {
        self.setScreenName("WatchAppInterfaceController")
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
    
    func setScreenName(name: String) {
//        let tracker = GAI.sharedInstance().defaultTracker
//        if nil == tracker {
//            return
//        }
//        tracker.set(kGAIScreenName, value: name)
//        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject])

        sendMessageToPhone([
            "trackScreenName": name
        ])
    }
    
    func trackEvent(category: String, action: String, label: String, value: NSNumber?) {
//        let tracker = GAI.sharedInstance().defaultTracker
//        if nil == tracker {
//            return
//        }
//        let trackDictionary = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value).build()
//        tracker.send(trackDictionary as [NSObject : AnyObject])

        // Send to iOS app using Watch Connectivity
        let valueToSend: NSNumber
        if let value = value {
            valueToSend = value
        } else {
            valueToSend = 0.0
        }
        let eventInfo: [String: AnyObject] = [
            "category": category,
            "action": action,
            "label": label,
            "value": valueToSend
        ]
        sendMessageToPhone([
            "trackEvent": eventInfo
        ])
    }
    
    func sendMessageToPhone(message: [String: AnyObject]) {
        // Send to iOS app using Watch Connectivity
        if true == WCSession.defaultSession().reachable {
            let session = WCSession.defaultSession()
            session.sendMessage(message, replyHandler: { reply in
                if let msg = reply["msg"] as? String {
                    print("Message from iPhone: \(msg)")
                }
                }, errorHandler: { error in
                    print("Error: \(error)")
            })
        } else {
            print("Could not reach iPhone using WCSession in setScreenName")
        }
    }
}

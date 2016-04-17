//
//  Site.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 13/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import CoreData

public class Site: NSManagedObject, MKAnnotation {
    static let entityName = "Site"

    // MARK: - MKAnnotation protocol variables
    public var title: String? {
        get {
            return self.siteName
        }
    }
    public var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
    }

    // MARK: - Init
    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    public init(dict: NSDictionary) {
        // Init with shared managed object context
        let entity =  NSEntityDescription.entityForName(
            Site.entityName,
            inManagedObjectContext: CoreDataStore.managedObjectContext
        )
        assert(nil != entity, "Entity 'Site' should never fail")
        super.init(entity: entity!, insertIntoManagedObjectContext: CoreDataStore.managedObjectContext)
        // Hopefully we can read info from the dictionary, otherwise use defaults
        if let dictLatitude = dict["latitude"] as? Double {
            self.latitude = dictLatitude
        }
        if let dictLongitude = dict["longitude"] as? Double {
            self.longitude = dictLongitude
        }
        if let dictSiteId = dict["SiteId"] as? Int {
            self.siteId = Int16(truncatingBitPattern: dictSiteId)
        }
        if let dictSiteName = dict["SiteName"] as? String {
            self.siteName = dictSiteName
        }
        if let dictFromCentralDirection = dict["from_central_direction"] as? Int {
            self.fromCentralDirection = Int16(truncatingBitPattern: dictFromCentralDirection)
        }
        if let dictStopAreaNumber = dict["StopAreaNumber"] as? Int {
            self.stopAreaNumber = Int16(truncatingBitPattern: dictStopAreaNumber)
        }
        if let dictStopAreaTypeCode = dict["StopAreaTypeCode"] as? String {
            self.stopAreaTypeCode = dictStopAreaTypeCode
        }
        // At first, do not activate bus stations
        self.isActive = ("BUSTERM" != self.stopAreaTypeCode)
        self.isChangedManual = false
        
        // Assert that we got real data
        assert(0.0 != self.latitude, "Must set real latitude")
        assert(0.0 != self.longitude, "Must set real longitude")
        assert(self.latitude != self.longitude, "We suspect coding error if latitude == longitude")
        assert(0   != self.siteId, "Must set real siteId")
        assert(""  != self.title, "Must set real title")
    }
    
    // MARK: - Change state av save to Core Data
    public func toggleActive() {
        isActive = !self.isActive
        isChangedManual = true
        CoreDataStore.saveContext()
    }
    
    // MARK: - Distance from location
    public func distanceFromLocation(location: CLLocation) -> CLLocationDistance {
        let ownLocation = CLLocation(coordinate: self.coordinate, altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, timestamp: NSDate())
        return ownLocation.distanceFromLocation(location)
    }
    
    // MARK: - Class functions
    public class func getAllSites() -> [Site] {
        let fetchRequest = NSFetchRequest(entityName: Site.entityName)
        do {
            if let sites = try CoreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as? [Site] {
                print("Got \(sites.count) sites back from DB")
                if sites.count > 0 {
                    return sites
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return Site.fillWithSites()
    }
    
    class func fillWithSites() -> [Site] {
        let hinnerJagKitBundle = NSBundle(forClass: CoreDataStore.classForCoder())
        let metroStationsFilePath = hinnerJagKitBundle.pathForResource("metro_stations", ofType: "json")
        assert(nil != metroStationsFilePath, "The file metro_stations.json must be included in the framework")
        let metroStationsData = NSData(contentsOfFile: metroStationsFilePath!)
        assert(nil != metroStationsData, "metro_stations.json must contain valid data")
        let responseDict = try! NSJSONSerialization.JSONObjectWithData(metroStationsData!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
        // Choose types of stations to include
        let stationTypes = ["METROSTN", "RAILWSTN", "TRAMSTN", "FERRYBER", "BUSTERM"]
        var siteList = [Site]()
        for type in stationTypes {
            // Add stations
            if let siteInfoList = responseDict[type] as! [NSDictionary]? {
                for info in siteInfoList {
                    siteList.append(Site(dict: info))
                }
            }
        }
        saveContext()
        return siteList
    }
    
    class func saveContext() {
        CoreDataStore.saveContext()
    }
}

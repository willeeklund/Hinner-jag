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
            inManagedObjectContext: CoreDataStore.managedObjectContext!
        )
        assert(nil != entity, "Entity 'Site' should never fail")
        super.init(entity: entity!, insertIntoManagedObjectContext: CoreDataStore.managedObjectContext)
        // Hopefully we can read info from the dictionary, otherwise use defaults
        if let dictLatitude = dict["latitude"] as? Double {
            latitude = dictLatitude
        }
        if let dictLongitude = dict["longitude"] as? Double {
            longitude = dictLongitude
        }
        if let dictSiteId = dict["SiteId"] as? Int {
            siteId = Int64(dictSiteId)
        }
        if let dictSiteName = dict["SiteName"] as? String {
            self.siteName = dictSiteName
        }
        if let dictFromCentralDirection = dict["from_central_direction"] as? Int {
            fromCentralDirection = Int64(dictFromCentralDirection)
        }
        if let dictStopAreaTypeCode = dict["StopAreaTypeCode"] as? String {
            stopAreaTypeCode = dictStopAreaTypeCode
        }
        // At first, do not activate bus stations
        isActive = ("BUSTERM" != self.stopAreaTypeCode)
        isChangedManual = false
        
        // Assert that we got real data
        assert(0.0 != latitude, "Must set real latitude")
        assert(0.0 != longitude, "Must set real longitude")
        assert(latitude != longitude, "We suspect coding error if latitude == longitude")
        assert(0   != siteId, "Must set real siteId")
        assert(""  != title, "Must set real title")
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
            if let sites = try CoreDataStore.managedObjectContext!.executeFetchRequest(fetchRequest) as? [Site] {
                print("Got \(sites.count) sites back from DB")
                if sites.count > 0 {
                    return sites
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        // Has not filled CoreData DB with sites before
        return Site.fillWithSites()
    }

    public class func getAllActiveSites() -> [Site] {
        let fetchRequest = NSFetchRequest(entityName: Site.entityName)
        fetchRequest.predicate = NSPredicate(format: "isActive = \(true)", argumentArray: nil)
        do {
            if let sites = try CoreDataStore.managedObjectContext!.executeFetchRequest(fetchRequest) as? [Site] {
                print("Got \(sites.count) active sites back from DB")
                if sites.count > 0 {
                    return sites
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        // Has not filled CoreData DB with sites before
        return Site.fillWithSites().filter({ $0.isActive })
    }
    
    // MARK: - Private helper functions
    
    /**
     Populate DB with all data from bundled JSON files
     
     Should only be called once, otherwise duplicates will occur
     */
    private class func fillWithSites() -> [Site] {
        CoreDataStore.batchDeleteEntity(Site.entityName)
        var siteList = [Site]()
        if let metroStationsDictionary = Site.readMetroStationsDictionary() {
            // Save to context after return
            defer {
                CoreDataStore.saveContext()
                // Begin filling DB with JourneyPatterns and StopAreas in background
                JourneyPattern.fillWithAllJourneyPatterns()
                StopArea.fillWithStopAreas()
            }
            // Include all types of stations
            let stationTypes = TransportType.all().map({ $0.stopAreaTypeCode() })
            for type in stationTypes {
                // Add stations
                if let siteInfoList = metroStationsDictionary[type] as? [NSDictionary] {
                    siteList.appendContentsOf(siteInfoList.map({ Site(dict: $0) }))
                }
            }
        }
        return siteList
    }
    
    private class func readMetroStationsDictionary() -> NSDictionary? {
        let hinnerJagKitBundle = NSBundle(forClass: CoreDataStore.classForCoder())
        let metroStationsFilePath = hinnerJagKitBundle.pathForResource("metro_stations", ofType: "json")
        assert(nil != metroStationsFilePath, "The file metro_stations.json must be included in the framework")
        let metroStationsData = NSData(contentsOfFile: metroStationsFilePath!)
        assert(nil != metroStationsData, "metro_stations.json must contain valid data")
        do {
            if let responseDict = try NSJSONSerialization.JSONObjectWithData(metroStationsData!, options: .MutableContainers) as? NSDictionary {
                return responseDict
            }
        } catch let error as NSError  {
            print("Could not parse JSON data: \(error), \(error.userInfo)")
        }
        return nil
    }

}

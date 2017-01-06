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

open class Site: NSManagedObject, MKAnnotation {
    static let entityName = "Site"

    // MARK: - MKAnnotation protocol variables
    open var title: String? {
        get {
            return self.siteName
        }
    }
    open var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
    }

    // MARK: - Init
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    public init(dict: NSDictionary) {
        // Init with shared managed object context
        let entity =  NSEntityDescription.entity(
            forEntityName: Site.entityName,
            in: CoreDataStore.managedObjectContext!
        )
        assert(nil != entity, "Entity 'Site' should never fail")
        super.init(entity: entity!, insertInto: CoreDataStore.managedObjectContext)
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
    open func toggleActive() {
        isActive = !self.isActive
        isChangedManual = true
        CoreDataStore.saveContext()
    }
    
    // MARK: - Distance from location
    open func distanceFromLocation(_ location: CLLocation) -> CLLocationDistance {
        let ownLocation = CLLocation(coordinate: self.coordinate, altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, timestamp: Date())
        return ownLocation.distance(from: location)
    }
    
    // MARK: - Class functions
    open class func getAllSites() -> [Site] {
        let fetchRequest: NSFetchRequest<Site> = NSFetchRequest(entityName: Site.entityName)
        do {
            let sites = try CoreDataStore.managedObjectContext!.fetch(fetchRequest)
            print("Got \(sites.count) sites back from DB")
            if sites.count > 0 {
                return sites
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        // Has not filled CoreData DB with sites before
        return Site.fillWithSites()
    }

    open class func getAllActiveSites() -> [Site] {
        let fetchRequest: NSFetchRequest<Site> = NSFetchRequest(entityName: Site.entityName)
        fetchRequest.predicate = NSPredicate(format: "isActive = \(true)", argumentArray: nil)
        do {
            let sites = try CoreDataStore.managedObjectContext!.fetch(fetchRequest)
            print("Got \(sites.count) active sites back from DB")
            if sites.count > 0 {
                return sites
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        // Has not filled CoreData DB with sites before
        return Site.fillWithSites().filter({ $0.isActive })
    }
    
    open class func getSite(id: Int64) -> Site? {
        let fetchRequest: NSFetchRequest<Site> = NSFetchRequest(entityName: Site.entityName)
        fetchRequest.predicate = NSPredicate(format: "siteId = %d", argumentArray: [id])
        do {
            let sites = try CoreDataStore.managedObjectContext!.fetch(fetchRequest)
            if 1 == sites.count {
                return sites.first
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return nil
    }

    
    // MARK: - Private helper functions
    
    /**
     Populate DB with all data from bundled JSON files
     
     Should only be called once, otherwise duplicates will occur
     */
    fileprivate class func fillWithSites() -> [Site] {
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
                    siteList.append(contentsOf: siteInfoList.map({ Site(dict: $0) }))
                }
            }
        }
        return siteList
    }
    
    fileprivate class func readMetroStationsDictionary() -> NSDictionary? {
        let hinnerJagKitBundle = Bundle(for: CoreDataStore.classForCoder())
        let metroStationsFilePath = hinnerJagKitBundle.path(forResource: "metro_stations", ofType: "json")
        assert(nil != metroStationsFilePath, "The file metro_stations.json must be included in the framework")
        let metroStationsData = try? Data(contentsOf: URL(fileURLWithPath: metroStationsFilePath!))
        assert(nil != metroStationsData, "metro_stations.json must contain valid data")
        do {
            if let responseDict = try JSONSerialization.jsonObject(with: metroStationsData!, options: .mutableContainers) as? NSDictionary {
                return responseDict
            }
        } catch let error as NSError  {
            print("Could not parse JSON data: \(error), \(error.userInfo)")
        }
        return nil
    }

}

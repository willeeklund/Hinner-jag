//
//  StopArea.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 30/05/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreData


open class StopArea: NSManagedObject {
    static let entityName = "StopArea"
    
    // MARK: - Init
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    public init(site linkedSite: Site, stopAreaNumber number: Int, stopAreaTypeCode chosenTypeCode: String?) {
        // Init with shared managed object context
        let entity =  NSEntityDescription.entity(
            forEntityName: StopArea.entityName,
            in: CoreDataStore.managedObjectContext!
        )
        assert(nil != entity, "Entity 'StopArea' should never fail")
        super.init(entity: entity!, insertInto: CoreDataStore.managedObjectContext)
        
        site = linkedSite
        stopAreaNumber = Int64(number)
        stopAreaTypeCode = chosenTypeCode

        assert(nil != site, "Must set real site")
        assert(0 != stopAreaNumber, "Must set real stopAreaNumber")
    }
    
    override open var description: String {
        return "StopArea(site: \(site), stopAreaNumber: \(stopAreaNumber), stopAreaTypeCode: \(stopAreaTypeCode))"
    }

    // MARK: - Class functions
    
    /**
     Populate DB with StopAreas
 
     Should only be called once, by Sites.fillWithSites()
     */
    class func fillWithStopAreas() {
        CoreDataStore.batchDeleteEntity(StopArea.entityName)
        if let stopAreaDictionary = StopArea.readStopAreasDictionary() {
            // Save to context after return
            defer { CoreDataStore.saveContext() }
            for site in Site.getAllSites() {
                // Add stop areas for each site
                if let stopAreaDictForSite = stopAreaDictionary["\(site.siteId)"] as? [NSDictionary] {
                    for stopAreaDict in stopAreaDictForSite {
                        if let stopAreaNumber = stopAreaDict["StopAreaNumber"] as? Int {
                            let typeCode = stopAreaDict["StopAreaTypeCode"] as? String // Could be nil, that is ok
                            _ = StopArea(site: site, stopAreaNumber: stopAreaNumber, stopAreaTypeCode: typeCode)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Private helper functions
    
    fileprivate class func readStopAreasDictionary() -> NSDictionary? {
        let hinnerJagKitBundle = Bundle(for: CoreDataStore.classForCoder())
        let stopAreasFilePath = hinnerJagKitBundle.path(forResource: "stopareasites", ofType: "json")
        assert(nil != stopAreasFilePath, "The file stopareasites.json must be included in the framework")
        let stopAreasData = try? Data(contentsOf: URL(fileURLWithPath: stopAreasFilePath!))
        assert(nil != stopAreasData, "stopareasites.json must contain valid data")
        do {
            if let responseDict = try JSONSerialization.jsonObject(with: stopAreasData!, options: .mutableContainers) as? NSDictionary {
                return responseDict["siteIdAndStopArea"] as? NSDictionary
            }
        } catch let error as NSError  {
            print("Could not parse JSON data: \(error), \(error.userInfo)")
        }
        return nil
    }

}

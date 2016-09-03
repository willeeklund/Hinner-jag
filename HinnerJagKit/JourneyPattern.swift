//
//  JourneyPattern.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 13/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreData


open class JourneyPattern: NSManagedObject {

    static let entityName = "JourneyPattern"
    
    // MARK: - Init
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    public init(dict: NSDictionary) {
        assert(nil != CoreDataStore.managedObjectContext, "Must be able to create managed object context")
        // Init with shared managed object context
        let entity =  NSEntityDescription.entity(
            forEntityName: JourneyPattern.entityName,
            in: CoreDataStore.managedObjectContext!
        )
        assert(nil != entity, "Entity 'JourneyPattern' should never fail")
        super.init(entity: entity!, insertInto: CoreDataStore.managedObjectContext)
        // Hopefully we can read info from the dictionary, otherwise use defaults
        if let dictLineNumberString = dict["LineNumber"] as? Int {
            lineNumber = Int64(dictLineNumberString)
        }
        if let dictPointNumberString = dict["StopAreaNumber"] as? Int {
            stopAreaNumber = Int64(dictPointNumberString)
        }
        
        // Assert that we got real data
        assert(0 != lineNumber, "Must set real lineNumber")
        assert(0 != stopAreaNumber, "Must set real stopAreaNumber")
    }
    
    override open var description: String {
        return "JourneyPattern(lineNumber: \(lineNumber), stopAreaNumber: \(stopAreaNumber))"
    }
    
    // MARK: - Class functions
    open class func getSitesForLine(_ lineNumber: Int, withStopAreaTypeCode chosenTypeCode: String?) -> [Site] {
        var sitesFromLine = [Site]()
        let fetchRequest: NSFetchRequest<JourneyPattern> = NSFetchRequest(entityName: JourneyPattern.entityName)
        // Use predicate to only fetch for this line number
        fetchRequest.predicate = NSPredicate(format: "lineNumber = \(lineNumber)", argumentArray: nil)
        do {
            let journeyPatterns = try CoreDataStore.managedObjectContext!.fetch(fetchRequest)
            if journeyPatterns.count > 0 {
                for point in journeyPatterns {
                    sitesFromLine.append(contentsOf: JourneyPattern.sitesFromStopAreaNumber(
                        point.stopAreaNumber,
                        withStopAreaTypeCode: chosenTypeCode
                    ))
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return sitesFromLine
    }
    
    /**
     Populate DB with JourneyPatterns
     
     Should only be called once, by Sites.fillWithSites()
     */
    class func fillWithAllJourneyPatterns() {
        CoreDataStore.batchDeleteEntity(JourneyPattern.entityName)
        let hinnerJagKitBundle = Bundle(for: CoreDataStore.classForCoder())
        let journeyPatternsFilePath = hinnerJagKitBundle.path(forResource: "journeypatternpoints", ofType: "json")
        assert(nil != journeyPatternsFilePath, "The file journeypatternpoints.json must be included in the framework")
        let journeyPatternsData = try? Data(contentsOf: URL(fileURLWithPath: journeyPatternsFilePath!))
        assert(nil != journeyPatternsData, "journeypatternpoints.json must contain valid data")
        do {
            if let responseDict = try JSONSerialization.jsonObject(with: journeyPatternsData!, options: .mutableContainers) as? NSDictionary {
                // Save to context after return
                defer { CoreDataStore.saveContext() }
                // Add journey patterns
                if let journeyPatternInfoList = responseDict["journeyPatternList"] as! [NSDictionary]? {
                    for info in journeyPatternInfoList {
                        _ = JourneyPattern(dict: info)
                    }
                } else {
                    print("Could not read 'journeyPatternList' from JSON file")
                }
            }
        } catch let error as NSError  {
            print("Could not parse JSON data: \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Toggle sites on line number
    /**
     Set all sites on a line number to a new value
     
     - parameters:
     - lineNumber: What line number to toggle
     - to: The new value of isActive for these Sites
     - withStopAreaTypeCode: require Sites to belong to a StopArea with this type of transportation
     
     - returns: Number of Sites that were changed as a result
     
     This will only change the value of the Bus stations along this line
     */
    open class func toggleSitesForLine(_ lineNumber: Int, to newActiveValue: Bool, withStopAreaTypeCode chosenTypeCode: String?) -> Int {
        // Save to context after return
        defer { CoreDataStore.saveContext() }
        var nbrChanged = 0
        // Create list of all Sites that were added as result of active Lines.
        // This is only interesting if current aim is to make sites inactive
        let activatedSitesByOtherLines = Line.sitesActivatedByActiveLines()
        let sites = JourneyPattern.getSitesForLine(lineNumber, withStopAreaTypeCode: chosenTypeCode)
        for site in sites {
            if
                !site.isChangedManual // Do not toggle manually edited sites
                    && nil != site.stopAreaTypeCode
                    && "BUSTERM" == site.stopAreaTypeCode! // Only toggle bus stations
                    && site.isActive != newActiveValue // We want to change active status
            {
                // Check if we wish to make a change for station
                // If action is to make site inactive, only do that if no other
                // active bus line goes through it
                if false == newActiveValue {
                    if activatedSitesByOtherLines.contains(site) {
                        continue
                    }
                }
                site.isActive = newActiveValue
                nbrChanged += 1
            }
        }
        // Send notification to update station list
        NotificationCenter.default.post(name: Notification.Name(rawValue: "LocateStationUpdateStationList"), object: nil)
        print("Did toggle \(nbrChanged) stations")
        return nbrChanged
    }
    
    // MARK: - Private class functions
    
    fileprivate class func sitesFromStopAreaNumber(_ stopAreaNumber: Int64, withStopAreaTypeCode chosenTypeCode: String?) -> [Site] {
        var siteList = [Site]()
        // Find the site for the stopAreaNumber
        let fetchRequest: NSFetchRequest<StopArea> = NSFetchRequest(entityName: StopArea.entityName)
        // Use predicate to only fetch for this stopAreaNumber
        fetchRequest.predicate = NSPredicate(format: "stopAreaNumber = \(stopAreaNumber)", argumentArray: nil)
        do {
            let stopAreaList = try CoreDataStore.managedObjectContext!.fetch(fetchRequest)
            for stopArea in stopAreaList {
                // If caller has chosen a stopAreaTypeCode to include, only include those
                if nil != chosenTypeCode && stopArea.stopAreaTypeCode != chosenTypeCode! {
                    continue
                }
                if let site = stopArea.site {
                    siteList.append(site)
                }
            }
        } catch let error as NSError {
            print("Something went wrong in JourneyPattern.sitesFromStopAreaNumber: \(error)")
        }
        return siteList
    }

}

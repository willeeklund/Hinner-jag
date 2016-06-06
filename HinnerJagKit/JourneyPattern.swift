//
//  JourneyPattern.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 13/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreData


public class JourneyPattern: NSManagedObject {

    static let entityName = "JourneyPattern"
    
    // MARK: - Init
    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    public init(dict: NSDictionary) {
        assert(nil != CoreDataStore.managedObjectContext, "Must be able to create managed object context")
        // Init with shared managed object context
        let entity =  NSEntityDescription.entityForName(
            JourneyPattern.entityName,
            inManagedObjectContext: CoreDataStore.managedObjectContext!
        )
        assert(nil != entity, "Entity 'JourneyPattern' should never fail")
        super.init(entity: entity!, insertIntoManagedObjectContext: CoreDataStore.managedObjectContext)
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
    
    override public var description: String {
        return "JourneyPattern(lineNumber: \(lineNumber), stopAreaNumber: \(stopAreaNumber))"
    }
    
    // MARK: - Class functions
    public class func getSitesForLine(lineNumber: Int, withStopAreaTypeCode chosenTypeCode: String?) -> [Site] {
        var sitesFromLine = [Site]()
        let fetchRequest = NSFetchRequest(entityName: JourneyPattern.entityName)
        // Use predicate to only fetch for this line number
        fetchRequest.predicate = NSPredicate(format: "lineNumber = \(lineNumber)", argumentArray: nil)
        do {
            if let journeyPatterns = try CoreDataStore.managedObjectContext!.executeFetchRequest(fetchRequest) as? [JourneyPattern] {
                if journeyPatterns.count > 0 {
                    for point in journeyPatterns {
                        sitesFromLine.appendContentsOf(JourneyPattern.sitesFromStopAreaNumber(
                            point.stopAreaNumber,
                            withStopAreaTypeCode: chosenTypeCode
                        ))
                    }
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
        let hinnerJagKitBundle = NSBundle(forClass: CoreDataStore.classForCoder())
        let journeyPatternsFilePath = hinnerJagKitBundle.pathForResource("journeypatternpoints", ofType: "json")
        assert(nil != journeyPatternsFilePath, "The file journeypatternpoints.json must be included in the framework")
        let journeyPatternsData = NSData(contentsOfFile: journeyPatternsFilePath!)
        assert(nil != journeyPatternsData, "journeypatternpoints.json must contain valid data")
        do {
            if let responseDict = try NSJSONSerialization.JSONObjectWithData(journeyPatternsData!, options: .MutableContainers) as? NSDictionary {
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
    public class func toggleSitesForLine(lineNumber: Int, to newActiveValue: Bool, withStopAreaTypeCode chosenTypeCode: String?) -> Int {
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
        NSNotificationCenter.defaultCenter().postNotificationName("LocateStationUpdateStationList", object: nil)
        print("Did toggle \(nbrChanged) stations")
        return nbrChanged
    }
    
    // MARK: - Private class functions
    
    private class func sitesFromStopAreaNumber(stopAreaNumber: Int64, withStopAreaTypeCode chosenTypeCode: String?) -> [Site] {
        var siteList = [Site]()
        // Find the site for the stopAreaNumber
        let fetchRequest = NSFetchRequest(entityName: StopArea.entityName)
        // Use predicate to only fetch for this stopAreaNumber
        fetchRequest.predicate = NSPredicate(format: "stopAreaNumber = \(stopAreaNumber)", argumentArray: nil)
        do {
            if let stopAreaList = try CoreDataStore.managedObjectContext!.executeFetchRequest(fetchRequest) as? [StopArea] {
                for stopArea in stopAreaList {
                    // If caller has chosen a stopAreaTypeCode to include, only include those
                    if nil != chosenTypeCode && stopArea.stopAreaTypeCode != chosenTypeCode! {
                        continue
                    }
                    if let site = stopArea.site {
                        siteList.append(site)
                    }
                }
            }
        } catch let error as NSError {
            print("Something went wrong in JourneyPattern.sitesFromStopAreaNumber: \(error)")
        }
        return siteList
    }

}

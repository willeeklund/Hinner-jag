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
        // Init with shared managed object context
        let entity =  NSEntityDescription.entityForName(
            JourneyPattern.entityName,
            inManagedObjectContext: CoreDataStore.managedObjectContext
        )
        assert(nil != entity, "Entity 'JourneyPattern' should never fail")
        super.init(entity: entity!, insertIntoManagedObjectContext: CoreDataStore.managedObjectContext)
        // Hopefully we can read info from the dictionary, otherwise use defaults
        if let dictLineNumber = dict["LineNumber"] as? Int {
            self.lineNumber = Int16(truncatingBitPattern: dictLineNumber)
        }
        if let dictStopAreaNumber = dict["StopAreaNumber"] as? Int {
            self.stopAreaNumber = Int16(truncatingBitPattern: dictStopAreaNumber)
        }
        
        // Assert that we got real data
        assert(0 != self.lineNumber, "Must set real lineNumber")
        assert(0 != self.stopAreaNumber, "Must set real stopAreaNumber")
    }
    
    // MARK: - Class functions
    public class func getSitesForLine(lineNumber: Int) -> [Site] {
        var sitesFromLine = [Site]()
        let fetchRequest = NSFetchRequest(entityName: JourneyPattern.entityName)
        // Use predicate to only fetch for this line number
        fetchRequest.predicate = NSPredicate(format: "lineNumber = \(lineNumber)", argumentArray: nil)
        do {
            if let journeyPatterns = try CoreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as? [JourneyPattern] {
                if journeyPatterns.count > 0 {
                    for point in journeyPatterns {
                        // Find the site for the stopAreaNumber
                        let fetchRequest = NSFetchRequest(entityName: Site.entityName)
                        // Use predicate to only fetch for this stopAreaNumber
                        fetchRequest.predicate = NSPredicate(format: "stopAreaNumber = \(point.stopAreaNumber)", argumentArray: nil)
                        if let sites = try CoreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as? [Site] {
                            sitesFromLine.appendContentsOf(sites)
                        }
                    }
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        if sitesFromLine.count > 0 {
            return sitesFromLine
        } else {
            return JourneyPattern.fillWithJourneyPatternsForLine(lineNumber)
        }
    }
    
    class func fillWithJourneyPatternsForLine(lineNumber: Int) -> [Site] {
        let hinnerJagKitBundle = NSBundle(forClass: CoreDataStore.classForCoder())
        let journeyPatternsFilePath = hinnerJagKitBundle.pathForResource("journeypatternpoints", ofType: "json")
        assert(nil != journeyPatternsFilePath, "The file journeypatternpoints.json must be included in the framework")
        let journeyPatternsData = NSData(contentsOfFile: journeyPatternsFilePath!)
        assert(nil != journeyPatternsData, "journeypatternpoints.json must contain valid data")
        var sitesFromLine = [Site]()
        do {
            if let responseDict = try NSJSONSerialization.JSONObjectWithData(journeyPatternsData!, options: .MutableContainers) as? NSDictionary {
                // Save to context after return
                defer {
                    CoreDataStore.saveContext()
                }
                // Add journey patterns
                if let journeyPatternInfoList = responseDict["journeyPatternList"] as! [NSDictionary]? {
                    for info in journeyPatternInfoList {
                        if let dictLineNumber = info["LineNumber"] as? Int {
                            // Only add journey pattern for chosen line
                            // This reduces initial wait time
                            if dictLineNumber == lineNumber {
                                let point = JourneyPattern(dict: info)
                                // Find the site for the stopAreaNumber
                                let fetchRequest = NSFetchRequest(entityName: Site.entityName)
                                // Use predicate to only fetch for this stopAreaNumber
                                fetchRequest.predicate = NSPredicate(format: "stopAreaNumber = \(point.stopAreaNumber)", argumentArray: nil)
                                if let sites = try CoreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as? [Site] {
                                    sitesFromLine.appendContentsOf(sites)
                                }
                            }
                        }
                    }
                } else {
                    print("Could not read 'journeyPatternList' from JSON file")
                }
            }
        } catch let error as NSError  {
            print("Could not parse JSON data: \(error), \(error.userInfo)")
        }
        return sitesFromLine
    }
    
    // MARK: - Toggle sites on line number
    /**
     Set all sites on a line number to a new value
     
     - parameters:
        - lineNumber: What line number to toggle
        - to: The new value of isActive for these Sites
     
     - returns: Number of Sites that were changed as a result
     
     This will only change the value of the Bus stations along this line
    */
    public class func toggleSitesForLine(lineNumber: Int, to newActiveValue: Bool) -> Int {
        // Save to context after return
        defer {
            CoreDataStore.saveContext()
        }
        var nbrChanged = 0
        // Create list of all Sites that were added as result of active Lines.
        // This is only interesting if current aim is to make sites inactive
        let activatedSitesByOtherLines = Line.sitesActivatedByActiveLines()
        let sites = JourneyPattern.getSitesForLine(lineNumber)
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

}

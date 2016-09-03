//
//  Line.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 13/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreData


open class Line: NSManagedObject {

    static let entityName = "Line"
    
    // MARK: - Init
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    public init(lineNumber newLineNumber: Int, withStopAreaTypeCode chosenTypeCode: String?, isActive activeValue: Bool) {
        assert(nil != CoreDataStore.managedObjectContext, "Must be able to create managed object context")
        // Init with shared managed object context
        let entity =  NSEntityDescription.entity(
            forEntityName: Line.entityName,
            in: CoreDataStore.managedObjectContext!
        )
        assert(nil != entity, "Entity 'Line' should never fail")
        super.init(entity: entity!, insertInto: CoreDataStore.managedObjectContext)
        lineNumber = Int64(newLineNumber)
        stopAreaTypeCode = chosenTypeCode
        isActive = activeValue
    }
    
    // MARK: - Class functions
    class func getActiveLines() -> [Line] {
        let fetchRequest: NSFetchRequest<Line> = NSFetchRequest(entityName: Line.entityName)
        // Use predicate to only fetch active lines
        fetchRequest.predicate = NSPredicate(format: "isActive = \(true)", argumentArray: nil)
        do {
            let lines = try CoreDataStore.managedObjectContext!.fetch(fetchRequest)
            return lines
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return [Line]()
    }
    
    class func getLinesForNumber(_ lineNumber: Int, withStopAreaTypeCode chosenTypeCode: String?) -> [Line] {
        let fetchRequest: NSFetchRequest<Line> = NSFetchRequest(entityName: Line.entityName)
        // Use predicate to only fetch for this line number
        fetchRequest.predicate = NSPredicate(format: "lineNumber = \(lineNumber)", argumentArray: nil)
        do {
            let lines = try CoreDataStore.managedObjectContext!.fetch(fetchRequest)
            return lines.filter() { line in
                if nil == chosenTypeCode {
                    return true
                } else if nil == line.stopAreaTypeCode {
                    return false
                } else {
                    return line.stopAreaTypeCode! == chosenTypeCode!
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return [Line]()
    }
    
    open class func isLineActive(_ lineNumber: Int, withStopAreaTypeCode chosenTypeCode: String?) -> Bool {
        let lines = Line.getLinesForNumber(lineNumber, withStopAreaTypeCode: chosenTypeCode)
        if lines.count > 0 {
            return lines.first!.isActive
        }
        return false
    }

    /**
     Toggle star status of a Line
     
     - parameters:
        - lineNumber: What line number to toggle
     
     - returns: Number of Sites that were changed as a result
     
     This will only change the value of the Bus stations along this line
     */
    open class func toggleLine(_ lineNumber: Int, withStopAreaTypeCode chosenTypeCode: String?) -> Int {
        // Save to context after return
        defer {
            CoreDataStore.saveContext()
        }
        // Toggle isActive for this Line
        let lines = Line.getLinesForNumber(lineNumber, withStopAreaTypeCode: chosenTypeCode)
        let newActiveValue: Bool
        if lines.count > 0 {
            // We have line already, toggle isActive value
            newActiveValue = !lines.first!.isActive
            lines.first!.isActive = newActiveValue
        } else {
            // Must create Line
            newActiveValue = true
            _ = Line(lineNumber: lineNumber, withStopAreaTypeCode: chosenTypeCode, isActive: newActiveValue)
        }
        // Post notification to track Google Analytics event
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: Constants.gaTrackEvent),
            object: nil,
            userInfo: [
                "category": "Line",
                "action": (newActiveValue ? "activate" : "inactivate"),
                "label": "Line \(lineNumber)",
                "value": (newActiveValue ? 1 : 0)
            ]
        )
        // Toggle sites on this journey pattern
        return JourneyPattern.toggleSitesForLine(lineNumber, to: newActiveValue, withStopAreaTypeCode: chosenTypeCode)
    }
    
    open class func sitesActivatedByActiveLines() -> [Site] {
        // Create list of all Sites that were added as result of active Lines.
        // This is only interesting if current aim is to make sites inactive
        var activatedSitesByOtherLines = [Site]()
        for activeLine in Line.getActiveLines() {
            // Add all these activated sites to activatedSites list
            let sites = JourneyPattern.getSitesForLine(
                Int(activeLine.lineNumber),
                withStopAreaTypeCode: activeLine.stopAreaTypeCode
            )
            activatedSitesByOtherLines.append(contentsOf: sites)
        }
        return activatedSitesByOtherLines
    }
}

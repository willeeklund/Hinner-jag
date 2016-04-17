//
//  Line.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 13/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreData


public class Line: NSManagedObject {

    static let entityName = "Line"
    
    // MARK: - Class functions
    class func getLinesForNumber(lineNumber: Int) -> [Line] {
        let fetchRequest = NSFetchRequest(entityName: Line.entityName)
        // Use predicate to only fetch for this line number
        fetchRequest.predicate = NSPredicate(format: "lineNumber = \(lineNumber)", argumentArray: nil)
        do {
            if let lines = try CoreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as? [Line] {
                return lines
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return [Line]()
    }
    
    public class func isLineActive(lineNumber: Int) -> Bool {
        let lines = Line.getLinesForNumber(lineNumber)
        if lines.count > 0 {
            return lines.first!.isActive
        }
        return false
    }

    public class func toggleLine(lineNumber: Int) -> Int {
        // Save to context after return
        defer {
            CoreDataStore.saveContext()
        }
        // Toggle isActive for this Line
        let lines = Line.getLinesForNumber(lineNumber)
        if lines.count > 0 {
            // We have line already, toggle isActive value
            lines.first!.isActive = !lines.first!.isActive
        } else {
            // Must create Line
            let entity =  NSEntityDescription.entityForName(
                Line.entityName,
                inManagedObjectContext: CoreDataStore.managedObjectContext
            )
            assert(nil != entity, "Entity 'JourneyPattern' should never fail")
            let newLine = Line(entity: entity!, insertIntoManagedObjectContext: CoreDataStore.managedObjectContext)
            newLine.lineNumber = Int16(truncatingBitPattern: lineNumber)
            newLine.isActive = true
        }
        // Toggle sites on this journey pattern
        return JourneyPattern.toggleSitesForLine(lineNumber)
    }
}

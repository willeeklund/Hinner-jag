//
//  JourneyPattern+CoreDataProperties.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 06/06/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension JourneyPattern {

    @NSManaged var directionCode: Int64
    @NSManaged var lineNumber: Int64
    @NSManaged var stopAreaNumber: Int64
    @NSManaged var line: Line?
    @NSManaged var stopArea: StopArea?

}

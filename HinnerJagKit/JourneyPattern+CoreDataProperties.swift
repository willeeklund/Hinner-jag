//
//  JourneyPattern+CoreDataProperties.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 13/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension JourneyPattern {

    @NSManaged var lineNumber: Int16
    @NSManaged var stopAreaNumber: Int16

}

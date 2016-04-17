//
//  Site+CoreDataProperties.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 17/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Site {

    @NSManaged public var fromCentralDirection: Int16
    @NSManaged public var isChangedManual: Bool
    @NSManaged public var isActive: Bool
    @NSManaged public var siteId: Int16
    @NSManaged var siteName: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var stopAreaNumber: Int16
    @NSManaged var stopAreaTypeCode: String?

}

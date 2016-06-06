//
//  Site+CoreDataProperties.swift
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

extension Site {

    @NSManaged public var fromCentralDirection: Int64
    @NSManaged public var isActive: Bool
    @NSManaged public var isChangedManual: Bool
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged public var siteId: Int64
    @NSManaged var siteName: String?
    @NSManaged var stopAreaTypeCode: String?
    @NSManaged var stopAreas: NSSet?

}

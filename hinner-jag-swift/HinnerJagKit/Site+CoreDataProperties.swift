//
//  Site+CoreDataProperties.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 30/05/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Site {

    @NSManaged var fromCentralDirection: NSNumber?
    @NSManaged var isActive: NSNumber?
    @NSManaged var isChangedManual: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var siteId: NSNumber?
    @NSManaged var siteName: String?
    @NSManaged var stopAreaNumber: NSNumber?
    @NSManaged var stopAreaTypeCode: String?
    @NSManaged var stopArea: NSSet?

}
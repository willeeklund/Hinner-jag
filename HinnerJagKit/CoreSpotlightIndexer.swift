//
//  CoreSpotlightIndexer.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 2017-01-06.
//  Copyright © 2017 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreSpotlight

@available(iOSApplicationExtension 9.0, *)
public class CoreSpotlightIndexer: NSObject, CSSearchableIndexDelegate {
    public static let siteType = "com.wilhelmeklund.Hinner-jag.siteType"
    public static let viewSiteActivityType = "com.wilhelmeklund.Hinner-jag.viewSiteActivityType"
    public static let identifierPrefix = "site"
    private let hasIndexedSitesKey = "hasIndexedSites1"
    
    public override init() {
        super.init()
        // Index if not done before
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: hasIndexedSitesKey) {
            DispatchQueue.global(qos: .utility).async {
                // Delete index
                CSSearchableIndex.default().deleteSearchableItems(
                    withDomainIdentifiers: [CoreSpotlightIndexer.identifierPrefix],
                    completionHandler: { [unowned self] _ in
                        // Fill index
                        self.searchableIndex(CSSearchableIndex.default(), reindexAllSearchableItemsWithAcknowledgementHandler: { [unowned self] in
                            defaults.set(true, forKey: self.hasIndexedSitesKey)
                            defaults.synchronize()
                        })
                })
            }
        }
    }
    
    public func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void)
    {
        // Need to use main queue because we get Site list from Core Data.
        DispatchQueue.main.async { [unowned self] in
            var searchableItems = [CSSearchableItem]()
            for site in Site.getAllSites() {
                if let searchItem = self.searchItemFrom(site: site) {
                    searchableItems.append(searchItem)
                }
            }
            searchableIndex.indexSearchableItems(searchableItems) { error in
                if nil != error {
                    print("Error indexing: \(error)")
                } else {
                    print("Done indexing of \(searchableItems.count) stations")
                    acknowledgementHandler()
                }
            }
        }
    }
    
    public func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        var searchableItems = [CSSearchableItem]()
        for site in Site.getAllSites() {
            let uniqueId = "\(CoreSpotlightIndexer.identifierPrefix)\(site.siteId)"
            guard identifiers.contains(uniqueId) else {
                continue
            }
            if let searchItem = searchItemFrom(site: site) {
                searchableItems.append(searchItem)
            }
        }
        searchableIndex.indexSearchableItems(searchableItems) { error in
            if nil != error {
                print("Error indexing: \(error)")
            } else {
                print("Done re-indexing of \(searchableItems.count) stations")
                acknowledgementHandler()
            }
        }
    }
    
    private func searchItemFrom(site: Site) -> CSSearchableItem? {
        guard site.title != nil else {
            // Site must have title to be searchable
            return nil
        }
        let uniqueId = "\(CoreSpotlightIndexer.identifierPrefix)\(site.siteId)"
        let searchAttributes = CoreSpotlightIndexer.attributeSetFrom(site: site)
        let searchItem = CSSearchableItem(uniqueIdentifier: uniqueId, domainIdentifier: CoreSpotlightIndexer.identifierPrefix, attributeSet: searchAttributes)
        return searchItem
    }
    
    public class func attributeSetFrom(site: Site) -> CSSearchableItemAttributeSet {
        let searchAttributes = CSSearchableItemAttributeSet(itemContentType: CoreSpotlightIndexer.siteType)
        searchAttributes.identifier = "\(site.siteId)"
        searchAttributes.title = site.title!
        searchAttributes.contentDescription = "Se avgångar just nu från \(site.title!)"
        searchAttributes.latitude = site.latitude as NSNumber
        searchAttributes.longitude = site.longitude as NSNumber
        return searchAttributes
    }
}

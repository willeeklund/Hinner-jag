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
        var searchableItems = [CSSearchableItem]()
        for site in Site.getAllSites() {
            if let searchItem = searchItemFrom(site: site) {
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
        guard let siteTitle = site.title else {
            // Site must have title to be searchable
            return nil
        }
        let uniqueId = "\(CoreSpotlightIndexer.identifierPrefix)\(site.siteId)"
        let searchAttributes = CSSearchableItemAttributeSet(itemContentType: CoreSpotlightIndexer.siteType)
        searchAttributes.title = siteTitle
        searchAttributes.contentDescription = "Se avgångar just nu från \(siteTitle)"
        let searchItem = CSSearchableItem(uniqueIdentifier: uniqueId, domainIdentifier: CoreSpotlightIndexer.identifierPrefix, attributeSet: searchAttributes)
        return searchItem
    }
    
    
}

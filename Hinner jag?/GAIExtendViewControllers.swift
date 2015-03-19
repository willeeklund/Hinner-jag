//
//  GAIExtendViewControllers.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 19/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import Foundation
import UIKit
import HinnerJagKit

extension UIViewController {
    func setScreeName(name: String) {
        self.title = name
        self.sendScreenView()
    }
    
    func sendScreenView() {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: self.title)
        tracker.send(GAIDictionaryBuilder.createScreenView().build())
    }
    
    func trackEvent(category: String, action: String, label: String, value: NSNumber?) {
        let tracker = GAI.sharedInstance().defaultTracker
        let trackDictionary = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value).build()
        tracker.send(trackDictionary)
    }
}
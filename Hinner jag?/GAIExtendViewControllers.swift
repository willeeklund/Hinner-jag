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
    
    func gaSetup() {
        let tracker = GAI.sharedInstance().defaultTracker
        if tracker != nil {
            print("Have already initialized tracker")
            return
        }
        let hinnerJagKitBundle = NSBundle(forClass: LocateStation.classForCoder())
        if let path = hinnerJagKitBundle.pathForResource("Info", ofType: "plist") {
            if let infoDict = NSDictionary(contentsOfFile: path) as? Dictionary<String, AnyObject> {
                if let gaTrackerId: String = infoDict["GA_TRACKING_ID"] as? String {
                    if gaTrackerId.hasPrefix("UA-") {
                        GAI.sharedInstance().trackUncaughtExceptions = true
                        GAI.sharedInstance().trackerWithTrackingId(gaTrackerId)
                    }
                }
            }
        }
    }
    
    func setScreenName(name: String) {
        self.title = name
        self.sendScreenView()
    }
    
    func sendScreenView() {
        let tracker = GAI.sharedInstance().defaultTracker
        if nil == tracker {
            return
        }
        tracker.set(kGAIScreenName, value: self.title)
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject])
    }
    
    func trackEvent(category: String, action: String, label: String, value: NSNumber?) {
        let tracker = GAI.sharedInstance().defaultTracker
        if nil == tracker {
            return
        }
        let trackDictionary = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value).build()
        tracker.send(trackDictionary as [NSObject : AnyObject])
    }
}
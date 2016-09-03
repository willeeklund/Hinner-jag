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

public extension UIViewController {
    
    public class func gaSetupTracker() {
        let tracker = GAI.sharedInstance().defaultTracker
        if tracker != nil {
            print("Have already initialized tracker")
            return
        }
        let hinnerJagKitBundle = Bundle(for: LocateStation.classForCoder())
        if let path = hinnerJagKitBundle.path(forResource: "Info", ofType: "plist") {
            if let infoDict = NSDictionary(contentsOfFile: path) as? Dictionary<String, AnyObject> {
                if let gaTrackerId: String = infoDict["GA_TRACKING_ID"] as? String {
                    if gaTrackerId.hasPrefix("UA-") {
                        GAI.sharedInstance().trackUncaughtExceptions = true
                        GAI.sharedInstance().tracker(withTrackingId: gaTrackerId)
                    }
                }
            }
        }
    }
    
    public func gaSetup() {
        UIViewController.gaSetupTracker()
        // Listen to GaTrackEvent notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGaTrackEvent),
            name: NSNotification.Name(rawValue: Constants.gaTrackEvent),
            object: nil
        )
    }
    
    func setScreenName(_ name: String) {
        self.title = name
        self.sendScreenView()
    }
    
    func sendScreenView() {
        let tracker = GAI.sharedInstance().defaultTracker
        if nil == tracker {
            return
        }
        tracker?.set(kGAIScreenName, value: self.title)
        tracker?.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject])
    }
    
    func trackEvent(_ category: String, action: String, label: String, value: NSNumber?) {
        let tracker = GAI.sharedInstance().defaultTracker
        if nil == tracker {
            return
        }
        print("trackEvent(\(category), \(action), \(label), \(value))")
        if let trackDictionary = GAIDictionaryBuilder.createEvent(withCategory: category, action: action, label: label, value: value).build() {
            tracker?.send(trackDictionary as [NSObject : AnyObject])
        }
    }
    
    // MARK: - GaTrackEvent notification listener
    func handleGaTrackEvent(_ notification: Notification) {
        // Only track if this view is shown on screen, avoid duplicates
        if (self.isViewLoaded && nil != self.view.window) {
            // Get event details from notification userInfo
            if let userInfo = (notification as NSNotification).userInfo {
                let category = userInfo["category"] as? String
                let action = userInfo["action"] as? String
                let label = userInfo["label"] as? String
                if
                    nil != category
                    && nil != action
                    && nil != label
                {
                    // If we have all mandatory fields, we can track the event
                    self.trackEvent(
                        category!,
                        action: action!,
                        label: label!,
                        value: userInfo["value"] as? NSNumber
                    )
                }
            }
        } else {
            print("UIViewController is not on screen and should not trackEvent")
        }
    }
}

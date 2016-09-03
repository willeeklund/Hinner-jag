//
//  AppDelegate.swift
//  Hinner jag?
//
//  Created by Wilhelm Eklund on 09/03/15.
//  Copyright (c) 2015 Wilhelm Eklund. All rights reserved.
//

import UIKit
import CoreData
import HinnerJagKit
import WatchConnectivity
import Fabric
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        CoreDataStore.saveContext()
    }
    
    // MARK: - Open custom URLs "hinner-jag://"
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        if nil == url.host {
            // If only opening the app, then we are done
            trackEvent("AppDelegate", action: "openUrl", label: "Only open HinnerJag, no route specified", value: nil)
            return true
        }
        // Find reference to mainVC
        if let mainVC = self.window?.rootViewController as? MainAppViewController {
            switch url.host! {
            case "map":
                // Show the map with selected line
                // Hide view controllers on top of mainVC
                mainVC.dismiss(animated: false, completion: nil)
                // Select chosen line from URL
                var selectedDict = Dictionary<String, AnyObject>()
                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
                for item in (urlComponents?.queryItems)! {
                    if "line" == item.name {
                        // Found specified line
                        if let value = item.value {
                            if let intValue = Int(value) {
                                selectedDict["lineNumber"] = intValue as AnyObject
                            }
                        }
                    } else if "stopAreaTypeCode" == item.name {
                        // Found specified stopAreaTypeCode
                        if let chosenStopAreaTypeCode = item.value {
                            selectedDict["stopAreaTypeCode"] = chosenStopAreaTypeCode as AnyObject
                        }
                    }
                }
                // Only show sites from selected line on map
                mainVC.performSegue(withIdentifier: "Show Map", sender: selectedDict)
                trackEvent("AppDelegate", action: "openUrl", label: url.absoluteString, value: nil)
                return true

            default:
                print("HinnerJag could not handle url: \(url)")
                trackEvent("AppDelegate", action: "openUrlFail", label: "HinnerJag could not handle url: \(url)", value: nil)
                return false
            }
        }
        return false
    }
    
    // MARK: - Watch Connectivity delegate
    @available(iOS 9.0, *)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Google analytics track screen name
        if let screenName = message["trackScreenName"] as? String {
            sendScreenViewToGA(screenName)
            replyHandler(["msg": "Tracked screen view of '\(screenName)' in GA" as AnyObject])
        }
    }

    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session activationDidCompleteWith state: \(activationState)")
    }

    @available(iOS 9.0, *)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }

    @available(iOS 9.0, *)
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }

    // MARK: - Google Analytics
    func trackEvent(_ category: String, action: String, label: String, value: NSNumber?) {
        UIViewController.gaSetupTracker()
        let tracker = GAI.sharedInstance().defaultTracker
        if nil == tracker {
            return
        }
        if let trackDictionary = GAIDictionaryBuilder.createEvent(withCategory: category, action: action, label: label, value: value).build() {
            tracker?.send(trackDictionary as [NSObject : AnyObject])
        }
    }
    
    func sendScreenViewToGA(_ name: String) {
        let tracker = GAI.sharedInstance().defaultTracker
        if nil == tracker {
            return
        }
        tracker?.set(kGAIScreenName, value: name)
        let eventTracker: NSDictionary = GAIDictionaryBuilder.createScreenView().build()
        tracker?.send(eventTracker as [NSObject : AnyObject])
    }
}

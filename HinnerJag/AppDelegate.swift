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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Fabric.with([Crashlytics.self])
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        CoreDataStore.saveContext()
    }
    
    // MARK: - Open custom URLs "hinner-jag://"
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        if nil == url.host {
            // If only opening the app, then we are done
            return true
        }
        // Find reference to mainVC
        if let mainVC = self.window?.rootViewController as? MainAppViewController {
            switch url.host! {
            case "map":
                // Show the map with selected line
                // Hide view controllers on top of mainVC
                mainVC.dismissViewControllerAnimated(false, completion: nil)
                // Select chosen line from URL
                var selectedLine: Int?
                let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
                for item in (urlComponents?.queryItems)! {
                    if "line" == item.name {
                        // Found specified line
                        if let value = item.value {
                            selectedLine = Int(value)
                            break
                        }
                    }
                }
                // Only show sites from selected line on map
                mainVC.performSegueWithIdentifier("Show Map", sender: selectedLine)
                return true

            default:
                print("HinnerJag could not handle url: \(url)")
                return false
            }
        }
        return false
    }
    
    // MARK: - Watch Connectivity delegate
    @available(iOS 9.0, *)
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        // Google analytics track screen name
        if let screenName = message["trackScreenName"] as? String {
            sendScreenViewToGA(screenName)
            replyHandler(["msg": "Tracked screen view of '\(screenName)' in GA"])
        }
    }
    
    func sendScreenViewToGA(name: String) {
        let tracker = GAI.sharedInstance().defaultTracker
        if nil == tracker {
            return
        }
        tracker.set(kGAIScreenName, value: name)
        let eventTracker: NSDictionary = GAIDictionaryBuilder.createScreenView().build()
        tracker.send(eventTracker as [NSObject : AnyObject])
    }
    
}

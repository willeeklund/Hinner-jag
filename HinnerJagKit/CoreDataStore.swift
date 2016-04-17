//
//  CoreDataStore.swift
//  Hinner jag
//
//  Created by Wilhelm Eklund on 13/04/16.
//  Copyright © 2016 Wilhelm Eklund. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataStore: NSObject {
    
    // MARK: - Core Data stack
    
    static var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.wilhelmeklund.Hinner_jag_" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    static var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        //        let modelURL = NSBundle.mainBundle().URLForResource("HinnerJag", withExtension: "momd")!
        let hinnerJagKitBundle = NSBundle(forClass: CoreDataStore.classForCoder())
        let modelURL = hinnerJagKitBundle.URLForResource("DataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    static var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: CoreDataStore.managedObjectModel)
        let url = CoreDataStore.applicationDocumentsDirectory.URLByAppendingPathComponent("Hinner_jag_.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error as NSError {
            coordinator = nil
            // Report any error we got.
            var dict = [NSObject: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()
    
    static var obj: NSManagedObjectContext?
    
    // MARK: - managedObjectContext
    
    public static var managedObjectContext: NSManagedObjectContext {
        get {
            if nil != CoreDataStore.obj {
                return CoreDataStore.obj!
            }
            let coordinator = CoreDataStore.persistentStoreCoordinator
            let managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = coordinator
            CoreDataStore.obj = managedObjectContext
            return managedObjectContext
        }
    }
    
    /**
     Save common managed object context
    */
    public static func saveContext() {
        do {
            try CoreDataStore.managedObjectContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
}
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
    
    static var applicationDocumentsDirectory: NSURL? = {
//        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.wilhelmeklund.Hinner-jag" in the application's documents Application Support directory.
//        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
//        return urls[urls.count-1]
        // Store application documents, such as sqlite file for CoreData, in App Group folder
        return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.wilhelmeklund.HinnerJagGroup")
    }()
    
    static var managedObjectModel: NSManagedObjectModel? = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        //        let modelURL = NSBundle.mainBundle().URLForResource("HinnerJag", withExtension: "momd")!
        let hinnerJagKitBundle = NSBundle(forClass: CoreDataStore.classForCoder())
        let modelURL = hinnerJagKitBundle.URLForResource("DataModel", withExtension: "momd")
        if nil == modelURL {
            print("CoreDataStore.managedObjectModel was nil. Could not find 'DataModel.momd'.")
            return nil
        }
        return NSManagedObjectModel(contentsOfURL: modelURL!)
    }()
    
    static var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        if nil == CoreDataStore.managedObjectModel {
            print("Error fetching CoreDataStore.managedObjectModel: it was nil")
            return nil
        }
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: CoreDataStore.managedObjectModel!)
            // Place to store sqlite file
            let sqliteUrl = CoreDataStore.applicationDocumentsDirectory?.URLByAppendingPathComponent("HinnerJag_2_1.sqlite")
            assert(nil != sqliteUrl, "Sqlite URL not found in App Group")
            assert(nil != coordinator, "coordinator could not be created")
            if
                nil == sqliteUrl || nil == coordinator
            {
                print("Either sqlite or coordinator was nil")
                return nil
            }
            try coordinator!.addPersistentStoreWithType(
                NSSQLiteStoreType,
                configuration: nil,
                URL: sqliteUrl!,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
            return coordinator
        } catch var error as NSError {
            // Report any error we got.
            var dict = [NSObject: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "HINNER_JAG_STHLM", code: 1, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error.userInfo)")
        } catch {
            print("Unknown fatal error occured creating CoreDataStore.persistentStoreCoordinator")
        }
        
        return nil
    }()
    
    static var obj: NSManagedObjectContext?
    
    // MARK: - managedObjectContext
    
    public static var managedObjectContext: NSManagedObjectContext? {
        get {
            if nil != CoreDataStore.obj {
                return CoreDataStore.obj!
            }
            let coordinator = CoreDataStore.persistentStoreCoordinator
            if nil == coordinator {
                return nil
            }
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator!
            CoreDataStore.obj = managedObjectContext
            return managedObjectContext
        }
    }
    
    /**
     Save common managed object context
     
     This is always performed on main queue, to be thread safe
    */
    public static func saveContext() {
        do {
            try CoreDataStore.managedObjectContext?.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    /**
     Fetch all items in entity and request to delete them
     */
    public static func batchDeleteEntity(entityName: String) {
        defer { CoreDataStore.saveContext() }
        do {
            if #available(iOSApplicationExtension 9.0, *) {
                try CoreDataStore.persistentStoreCoordinator?.executeRequest(
                    NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: entityName)),
                    withContext: CoreDataStore.managedObjectContext!
                )
            } else {
                // Fallback on earlier versions
                let fetchRequest = NSFetchRequest(entityName: entityName)
                let objectList = try CoreDataStore.managedObjectContext!.executeFetchRequest(fetchRequest)
                if let managedObjectList = objectList as? [NSManagedObject] {
                    _ = managedObjectList.map({
                        CoreDataStore.managedObjectContext!.deleteObject($0)
                    })
                }
            }
        } catch let error as NSError {
            print(error)
        }
    }
}

import Foundation
import UIKit
import CoreData

class Persistence {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PhotoBackup")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // TODO handle and report to user
                fatalError("Unable to initialize persistent container \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // TODO handle and report to user
                let nserror = error as NSError
                NSLog("Unable to save context \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

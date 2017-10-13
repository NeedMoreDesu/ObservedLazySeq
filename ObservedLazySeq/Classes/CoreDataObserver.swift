//
//  CoreDataObserver.swift
//  ObservedLazySeq
//
//  Created by Oleksii Horishnii on 10/13/17.
//

import Foundation
import CoreData
import LazySeq

struct FetchRequestParameters {
    var predicate: NSPredicate?
    var sortDescriptors: [NSSortDescriptor]?
}

class CoreDataObserver: NSObject, NSFetchedResultsControllerDelegate {
    private var controller: NSFetchedResultsController<NSManagedObject>
    private class func fetchResultController(entityName: String,
                                             primaryKey: String,
                                             managedObjectContext: NSManagedObjectContext,
                                             params: FetchRequestParameters? = nil) -> NSFetchedResultsController<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = params?.predicate
        request.fetchBatchSize = 20
        if let sortDesc = params?.sortDescriptors {
            request.sortDescriptors = sortDesc
        } else {
            request.sortDescriptors = [NSSortDescriptor(key: primaryKey, ascending: true)]
        }
        
        let fetchedResultsController = NSFetchedResultsController<NSManagedObject>(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            abort()
        }
        
        return fetchedResultsController
    }
    
    init(entityName: String,
         primaryKey: String,
         managedObjectContext: NSManagedObjectContext,
         params: FetchRequestParameters? = nil) {
        let fetchedResultController = CoreDataObserver.fetchResultController(entityName: entityName,
                                                                             primaryKey: primaryKey,
                                                                             managedObjectContext: managedObjectContext,
                                                                             params: params)
        self.controller = fetchedResultController
        
        super.init()
        
        fetchedResultController.delegate = self
    }
    class func create(entityName: String,
                      primaryKey: String,
                      managedObjectContext: NSManagedObjectContext,
                      params: FetchRequestParameters? = nil) -> ObservedLazySeq<NSManagedObject> {
        let observer = CoreDataObserver(entityName: entityName,
                                        primaryKey: primaryKey,
                                        managedObjectContext: managedObjectContext,
                                        params: params)
        let observedLazySeq = ObservedLazySeq<NSManagedObject>(strongRefs: [observer])
        observer.observedLazySeq = observedLazySeq
        return observedLazySeq
    }
    
    weak var observedLazySeq: ObservedLazySeq<NSManagedObject>? {
        didSet {
            observedLazySeq?.objs = LazySeq<NSManagedObject>(count: { () -> Int in
                if let section = self.controller.sections?.first {
                    return section.numberOfObjects
                }
                return 0
            }, generate: { (idx, _) -> NSManagedObject? in
                let obj = self.controller.object(at: IndexPath(row: idx, section: 0))
                return obj
            })
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.observedLazySeq?.willChangeContent?()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.observedLazySeq?.didChangeContent?()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        var type = type
        if (type == .update && newIndexPath != nil && indexPath?.compare(newIndexPath!) != .orderedSame) {
            type = .move;
        }
        switch type {
        case .insert:
            if let row = newIndexPath?.row {
                self.observedLazySeq?.insertFn?(row)
            }
        case .delete:
            if let row = indexPath?.row {
                self.observedLazySeq?.deleteFn?(row)
            }
        case .update:
            if let row = indexPath?.row {
                self.observedLazySeq?.updateFn?(row)
            }
        case .move:
            if let row = indexPath?.row,
                let newRow = newIndexPath?.row {
                self.observedLazySeq?.moveFn?(row, newRow)
            }
        }
    }
}

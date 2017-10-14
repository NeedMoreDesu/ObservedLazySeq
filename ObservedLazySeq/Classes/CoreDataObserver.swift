//
//  CoreDataObserver.swift
//  ObservedLazySeq
//
//  Created by Oleksii Horishnii on 10/13/17.
//

import Foundation
import CoreData
import LazySeq

public struct FetchRequestParameters {
    var predicate: NSPredicate?
    var sortDescriptors: [NSSortDescriptor]?
    var fetchBatchSize: Int?
}

open class CoreDataObserver: NSObject, NSFetchedResultsControllerDelegate {
    private var controller: NSFetchedResultsController<NSManagedObject>
    private class func fetchResultController(entityName: String,
                                             primaryKey: String,
                                             managedObjectContext: NSManagedObjectContext,
                                             params: FetchRequestParameters? = nil) -> NSFetchedResultsController<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = params?.predicate
        request.fetchBatchSize = params?.fetchBatchSize ?? 20
        request.sortDescriptors = params?.sortDescriptors ?? [NSSortDescriptor(key: primaryKey, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController<NSManagedObject>(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            abort()
        }
        
        return fetchedResultsController
    }
    
    private class func fetchResultController(fetchRequest: NSFetchRequest<NSManagedObject>,
                                             managedObjectContext: NSManagedObjectContext) -> NSFetchedResultsController<NSManagedObject> {
        let request = fetchRequest
        
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
    
    init(fetchRequest: NSFetchRequest<NSManagedObject>,
         managedObjectContext: NSManagedObjectContext) {
        let fetchedResultController = CoreDataObserver.fetchResultController(fetchRequest: fetchRequest,
                                                                             managedObjectContext: managedObjectContext)
        self.controller = fetchedResultController
        
        super.init()
        
        fetchedResultController.delegate = self
    }
    
    public class func create(entityName: String,
                      primaryKey: String,
                      managedObjectContext: NSManagedObjectContext,
                      params: FetchRequestParameters? = nil) -> LazySeq<ObservedLazySeq<NSManagedObject>> {
        let observer = CoreDataObserver(entityName: entityName,
                                        primaryKey: primaryKey,
                                        managedObjectContext: managedObjectContext,
                                        params: params)
        
        return observer.setupObservedSections()
    }
    
    public class func create(fetchRequest: NSFetchRequest<NSManagedObject>,
                             managedObjectContext: NSManagedObjectContext) -> LazySeq<ObservedLazySeq<NSManagedObject>> {
        let observer = CoreDataObserver(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext)
        
        return observer.setupObservedSections()
    }
    
    weak var observedSections: LazySeq<ObservedLazySeq<NSManagedObject>>?
    private func setupObservedSections() -> LazySeq<ObservedLazySeq<NSManagedObject>> {
        let sections = LazySeq(count: { () -> Int in
            return self.controller.sections?.count ?? 0
        }) { (sectionIdx, _) -> ObservedLazySeq<NSManagedObject> in
            let observedLazySeq = ObservedLazySeq<NSManagedObject>(strongRefs: [self])
            observedLazySeq.objs = GeneratedSeq<NSManagedObject>(count: { () -> Int in
                if let section = self.controller.sections?[sectionIdx] {
                    return section.numberOfObjects
                }
                return 0
            }, generate: { (idx, _) -> NSManagedObject? in
                let obj = self.controller.object(at: IndexPath(row: idx, section: sectionIdx))
                return obj
            })
            return observedLazySeq
        }
        
        self.observedSections = sections
        
        return sections
    }
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let seqs = self.observedSections else {
            return
        }
        for observedLazySeq in seqs {
            observedLazySeq.willChangeContent?()
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let seqs = self.observedSections else {
            return
        }
        for observedLazySeq in seqs {
            observedLazySeq.didChangeContent?()
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
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
            if let row = newIndexPath?.row,
                let section = newIndexPath?.section {
                self.observedSections?[section].insertFn?(row)
            }
        case .delete:
            if let row = indexPath?.row,
                let section = indexPath?.section {
                self.observedSections?[section].deleteFn?(row)
            }
        case .update:
            if let row = indexPath?.row,
                let section = indexPath?.section {
                self.observedSections?[section].updateFn?(row)
            }
        case .move:
            if let row = indexPath?.row,
                let newRow = newIndexPath?.row,
                let section = indexPath?.section,
                let newSection = newIndexPath?.section {
                if (section == newSection) {
                    self.observedSections?[section].moveFn?(row, newRow)
                } else {
                    self.observedSections?[section].deleteFn?(row)
                    self.observedSections?[newSection].insertFn?(newRow)
                }
            }
        }
    }
}

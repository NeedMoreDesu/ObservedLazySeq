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

class Weak<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}

open class CoreDataObserver<Type>: NSObject, NSFetchedResultsControllerDelegate where Type: NSManagedObject {
    private var controller: NSFetchedResultsController<Type>
    private class func fetchResultController(entityName: String,
                                             primaryKey: String,
                                             managedObjectContext: NSManagedObjectContext,
                                             params: FetchRequestParameters? = nil) -> NSFetchedResultsController<Type> {
        let request = NSFetchRequest<Type>(entityName: entityName)
        request.predicate = params?.predicate
        request.fetchBatchSize = params?.fetchBatchSize ?? 20
        request.sortDescriptors = params?.sortDescriptors ?? [NSSortDescriptor(key: primaryKey, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController<Type>(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            abort()
        }
        
        return fetchedResultsController
    }
    
    private class func fetchResultController(fetchRequest: NSFetchRequest<Type>,
                                             managedObjectContext: NSManagedObjectContext) -> NSFetchedResultsController<Type> {
        let request = fetchRequest
        
        let fetchedResultsController = NSFetchedResultsController<Type>(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
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
    
    init(fetchRequest: NSFetchRequest<Type>,
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
                      params: FetchRequestParameters? = nil) -> LazySeq<ObservedLazySeq<Type>> {
        let observer = CoreDataObserver(entityName: entityName,
                                        primaryKey: primaryKey,
                                        managedObjectContext: managedObjectContext,
                                        params: params)
        
        return observer.setupObservedSections()
    }
    
    public class func create(fetchRequest: NSFetchRequest<Type>,
                             managedObjectContext: NSManagedObjectContext) -> LazySeq<ObservedLazySeq<Type>> {
        let observer = CoreDataObserver(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext)
        
        return observer.setupObservedSections()
    }
    
    var observedSections: [Int: Weak<ObservedLazySeq<Type>>] = [:]
    private func setupObservedSections() -> LazySeq<ObservedLazySeq<Type>> {
        let sections = LazySeq(count: { () -> Int in
            return self.controller.sections?.count ?? 0
        }) { (sectionIdx, _) -> ObservedLazySeq<Type> in
            let observedLazySeq = ObservedLazySeq<Type>(strongRefs: [self])
            observedLazySeq.objs = GeneratedSeq<Type>(count: { () -> Int in
                if let sections = self.controller.sections {
                    if sectionIdx < sections.count {
                        return sections[sectionIdx].numberOfObjects
                    }
                }
                return 0
            }, generate: { (idx, _) -> Type? in
                let obj = self.controller.object(at: IndexPath(row: idx, section: sectionIdx))
                return obj
            })
            self.observedSections[sectionIdx] = Weak(value: observedLazySeq)
            return observedLazySeq
        }
        
        let _ = sections.first // implicitly trigger first row ObservedLazySeq creation so strongRef isn't wasted
        
        return sections
    }
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        for (_, observedLazySeq) in self.observedSections {
            observedLazySeq.value?.willChangeContent?()
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        for (_, observedLazySeq) in self.observedSections {
            observedLazySeq.value?.didChangeContent?()
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
                self.observedSections[section]?.value?.insertFn?(row)
            }
        case .delete:
            if let row = indexPath?.row,
                let section = indexPath?.section {
                self.observedSections[section]?.value?.deleteFn?(row)
            }
        case .update:
            if let row = indexPath?.row,
                let section = indexPath?.section {
                self.observedSections[section]?.value?.updateFn?(row)
            }
        case .move:
            if let row = indexPath?.row,
                let newRow = newIndexPath?.row,
                let section = indexPath?.section,
                let newSection = newIndexPath?.section {
                if (section == newSection) {
                    self.observedSections[section]?.value?.moveFn?(row, newRow)
                } else {
                    self.observedSections[section]?.value?.deleteFn?(row)
                    self.observedSections[newSection]?.value?.insertFn?(newRow)
                }
            }
        }
    }
}

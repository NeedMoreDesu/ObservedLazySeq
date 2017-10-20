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
    public var predicate: NSPredicate?
    public var sortDescriptors: [NSSortDescriptor]?
    public var fetchBatchSize: Int?
    public var sectionNameKeyPath: String?
    public init() {}
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
        
        let fetchedResultsController = NSFetchedResultsController<Type>(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: params?.sectionNameKeyPath, cacheName: nil)
        
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
    
    init(fetchedResultController: NSFetchedResultsController<Type>) {
        self.controller = fetchedResultController
        
        super.init()
        
        fetchedResultController.delegate = self
    }
    
    public class func create(entityName: String,
                      primaryKey: String,
                      managedObjectContext: NSManagedObjectContext,
                      params: FetchRequestParameters? = nil) -> ObservedLazySeq<Type> {
        let observer = CoreDataObserver(entityName: entityName,
                                        primaryKey: primaryKey,
                                        managedObjectContext: managedObjectContext,
                                        params: params)
        
        return observer.setupObservedSections()
    }
    
    public class func create(fetchedResultController: NSFetchedResultsController<Type>) -> ObservedLazySeq<Type> {
        let observer = CoreDataObserver(fetchedResultController: fetchedResultController)
        
        return observer.setupObservedSections()
    }
    
    weak var observed: ObservedLazySeq<Type>?
    private func setupObservedSections() -> ObservedLazySeq<Type> {
        let observed = ObservedLazySeq<Type>(strongRefs: [self])
        let objs = LazySeq(count: { () -> Int in
            return self.controller.sections?.count ?? 0
        }) { (sectionIdx, _) -> GeneratedSeq<Type> in
            return GeneratedSeq<Type>(count: { () -> Int in
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
        }
        
        observed.objs = objs
        self.observed = observed
        
        return observed
    }
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.observed?.willChangeContent?()
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.observed?.didChangeContent?()
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
                self.observed?.insertRowFn?(row, section)
            }
        case .delete:
            if let row = indexPath?.row,
                let section = indexPath?.section {
                self.observed?.deleteRowFn?(row, section)
            }
        case .update:
            if let row = indexPath?.row,
                let section = indexPath?.section {
                self.observed?.updateRowFn?(row, section)
            }
        case .move:
            if let oldRow = indexPath?.row,
                let newRow = newIndexPath?.row,
                let oldSection = indexPath?.section,
                let newSection = newIndexPath?.section {
                self.observed?.deleteRowFn?(oldSection, oldRow)
                self.observed?.insertRowFn?(newSection, newRow)
            }
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch (type) {
        case .insert:
            (self.observed?.objs as? LazySeq)?.resetStorage()
            self.observed?.insertSectionFn?(sectionIndex)
            break
        case .delete:
            (self.observed?.objs as? LazySeq)?.resetStorage()
            self.observed?.deleteSectionFn?(sectionIndex)
            break
        default:
            break
        }
    }
}

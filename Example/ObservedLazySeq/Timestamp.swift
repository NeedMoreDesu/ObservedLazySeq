//
//  Timestamp.swift
//  ObservedLazySeq_Example
//
//  Created by Oleksii Horishnii on 10/19/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import CoreData
import ObservedLazySeq
import LazySeq

extension Timestamp {
    class func entityDescription(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Timestamp", in: context)!
    }
    
    class func create(context: NSManagedObjectContext = CoreData.shared.dataStack.mainContext) -> Timestamp {
        let timestamp = Timestamp(entity: self.entityDescription(context: context), insertInto: context)
        timestamp.time = Date()
        return timestamp
    }
    
    class func createObservedLazySeq(context: NSManagedObjectContext = CoreData.shared.dataStack.mainContext) -> LazySeq<ObservedLazySeq<Timestamp>> {
        let managedObjectsObserved = CoreDataObserver<Timestamp>.create(entityName: "Timestamp", primaryKey: "time", managedObjectContext: context)
        return managedObjectsObserved
    }
    
    func delete() {
        self.managedObjectContext?.delete(self)
    }
}

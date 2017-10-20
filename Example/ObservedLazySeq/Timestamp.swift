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
    var second: String {
        let calendar = Calendar.current
        
        let second = calendar.component(.second, from: self.time!)
        return "\(second)s"
    }
    
    class func entityDescription(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Timestamp", in: context)!
    }
    
    class func create(context: NSManagedObjectContext = CoreData.shared.dataStack.mainContext) -> Timestamp {
        let timestamp = Timestamp(entity: self.entityDescription(context: context), insertInto: context)
        timestamp.time = Date()
        return timestamp
    }
    
    class func createObservedLazySeq(context: NSManagedObjectContext = CoreData.shared.dataStack.mainContext) -> ObservedLazySeq<Timestamp> {
        var params = FetchRequestParameters()
        params.sectionNameKeyPath = "second"
        params.sortDescriptors = [NSSortDescriptor(key: "second", ascending: true), NSSortDescriptor(key: "time", ascending: true)]
        let managedObjectsObserved = CoreDataObserver<Timestamp>.create(entityName: "Timestamp", primaryKey: "time", managedObjectContext: context, params: params)
        return managedObjectsObserved
    }
    
    func delete() {
        self.managedObjectContext?.delete(self)
    }
}

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

extension DBTimestamp {
    static let entityName = "DBTimestamp"
    class func entityDescription(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: entityName, in: context)!
    }
    
    class func create(context: NSManagedObjectContext = CoreData.shared.dataStack.mainContext) -> DBTimestamp {
        let timestamp = DBTimestamp(entity: self.entityDescription(context: context), insertInto: context)
        
        let currentDate = Date()
        
        let calendar = Calendar.current
        let second = calendar.component(.second, from: currentDate)

        timestamp.time = currentDate
        timestamp.second = Int16(second)
        
        return timestamp
    }
    
    class func createObservedLazySeq(context: NSManagedObjectContext = CoreData.shared.dataStack.mainContext) -> ObservedLazySeq<DBTimestamp> {
        var params = FetchRequestParameters()
        params.sectionNameKeyPath = "second"
        params.sortDescriptors = [NSSortDescriptor(key: "second", ascending: true), NSSortDescriptor(key: "time", ascending: true)]
        let managedObjectsObserved = CoreDataObserver<DBTimestamp>.create(entityName: entityName, primaryKey: "time", managedObjectContext: context, params: params)
        return managedObjectsObserved
    }
    
    func delete() {
        self.managedObjectContext?.delete(self)
    }
}

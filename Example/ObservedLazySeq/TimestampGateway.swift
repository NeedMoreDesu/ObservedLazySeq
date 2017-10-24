//
//  TimestampGateway.swift
//  ObservedLazySeq_Example
//
//  Created by Oleksii Horishnii on 10/24/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import ObservedLazySeq
import LazySeq

class TimestampGateway: TimestampRouter {
    private let databaseObserved = DBTimestamp.createObservedLazySeq()
    private func toTimestampEntity(dbobj: DBTimestamp) -> Timestamp {
        return Timestamp(time: dbobj.time!)
    }
    
    func observed() -> ObservedLazySeq<Timestamp> {
        return self.databaseObserved.map(self.toTimestampEntity)
    }
    
    func sectionSeconds() -> GeneratedSeq<Seconds> {
        return self.databaseObserved.objs.map({ (section) -> Seconds in
            let second = section.first()?.second ?? 0
            return Seconds(value: Int(second))
        })
    }
    
    func createTimestamp() -> Timestamp {
        let dbTimestamp = DBTimestamp.create()
        CoreData.shared.save()
        return toTimestampEntity(dbobj: dbTimestamp)
    }
    
    func deleteTimestampAt(indexPath: IndexPath) {
        let item = self.databaseObserved.getItemAt(indexPath)
        item.delete()
    }
}

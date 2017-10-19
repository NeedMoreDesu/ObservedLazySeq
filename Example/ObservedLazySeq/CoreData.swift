//
//  CoreData.swift
//  ObservedLazySeq_Example
//
//  Created by Oleksii Horishnii on 10/19/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DATAStack

class CoreData: NSObject {
    static var shared: CoreData = CoreData()
    
    var dataStack = DATAStack(modelName: "Model")
    
    //MARK:- Database protocol implementation
    
    private var saveTransactionValue = 0
    func save() {
        if (saveTransactionValue == 0) {
            try! self.dataStack.mainContext.save()
        }
    }
    
    func saveTransaction<Type>(_ fn: (() -> Type)) -> Type {
        saveTransactionValue = saveTransactionValue + 1;
        let value = fn()
        saveTransactionValue = saveTransactionValue - 1;
        save()
        return value
    }
}

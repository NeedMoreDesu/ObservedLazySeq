//
//  ObservedLazySeq.swift
//  PerfectExample
//
//  Created by Oleksii Horishnii on 1/28/17.
//  Copyright © 2017 Oleksii Horishnii. All rights reserved.
//

import UIKit
import LazySeq

open class ObservedLazySeq<Type> {
    public private(set) var strongRefs: [AnyObject]
    
    public var objs: GeneratedSeq<Type>!
    
    public var willChangeContent: (() -> Void)?
    public var didChangeContent: (() -> Void)?
    
    public var insertFn: ((_ idx: Int) -> Void)?
    public var deleteFn: ((_ idx: Int) -> Void)?
    public var updateFn: ((_ idx: Int) -> Void)?
    public var moveFn: ((_ oldIdx: Int, _ newIdx: Int) -> Void)?

    public var fullReloadFn: (() -> Void)?
    
    public init(strongRefs: [AnyObject], objs: GeneratedSeq<Type>? = nil) {
        self.strongRefs = strongRefs
        self.objs = objs
    }
    
    public func subscribeDefault<Type2>(observed: ObservedLazySeq<Type2>, startingIndex: Int = 0) {
        self.willChangeContent = {
            observed.willChangeContent?()
        }
        self.didChangeContent = {
            observed.didChangeContent?()
        }

        self.insertFn = { idx in
            (self.objs as? LazySeq)?.resetStorage()
            let idx = idx + startingIndex
            observed.insertFn?(idx)
        }
        self.deleteFn = { idx in
            (self.objs as? LazySeq)?.resetStorage()
            let idx = idx + startingIndex
            observed.deleteFn?(idx)
        }
        self.updateFn = { idx in
            (self.objs as? LazySeq)?.resetStorage()
            let idx = idx + startingIndex
            observed.updateFn?(idx)
        }
        self.moveFn = { idx, newIdx in
            (self.objs as? LazySeq)?.resetStorage()
            let idx = idx + startingIndex
            let newIdx = newIdx + startingIndex
            observed.moveFn?(idx, newIdx)
        }
        
        self.fullReloadFn = {
            (self.objs as? LazySeq)?.resetStorage()
            observed.fullReloadFn?()
        }
    }
}

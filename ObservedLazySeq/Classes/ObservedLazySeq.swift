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
    
    public func map<ReturnType>(_ transform: @escaping (Type) -> ReturnType?) -> ObservedLazySeq<ReturnType> {
        let observed = ObservedLazySeq<ReturnType>(strongRefs: self.strongRefs, objs: self.objs.map(transform))
        self.subscribeDefault(observed: observed)
        return observed
    }
    
    public func subscribeDefault<ResultType>(observed: ObservedLazySeq<ResultType>, startingIndex: Int = 0) {
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
    
    public func subscribeTableView(tableView: UITableView, startingIndex: Int = 0, section: Int = 0) {
        self.willChangeContent = { [weak tableView] in
            tableView?.beginUpdates()
        }
        self.insertFn = { [weak tableView] (idx) in
            tableView?.insertRows(at: [IndexPath.init(row: idx + startingIndex, section: section)], with: .automatic)
        }
        self.deleteFn = { [weak tableView] (idx) in
            tableView?.deleteRows(at: [IndexPath.init(row: idx + startingIndex, section: section)], with: .fade)
        }
        self.updateFn = { [weak tableView] (idx) in
            tableView?.reloadRows(at: [IndexPath.init(row: idx + startingIndex, section: section)], with: .automatic)
        }
        self.moveFn = { [weak tableView] (oldIdx, newIdx) in
            tableView?.deleteRows(at: [IndexPath.init(row: oldIdx + startingIndex, section: section)], with: .automatic)
            tableView?.insertRows(at: [IndexPath.init(row: newIdx + startingIndex, section: section)], with: .automatic)
        }
        self.fullReloadFn = { [weak tableView] in
            tableView?.reloadData()
        }
        self.didChangeContent = { [weak tableView] in
            tableView?.endUpdates()
        }
    }
}

public extension UITableView {
    public func subscribeToObservedSections<Type>(observedLazySeqs: GeneratedSeq<ObservedLazySeq<Type>>, startingRows: [Int] = [], startingSection: Int = 0) {
        for (section, observedLazySeq) in observedLazySeqs.enumerated() {
            var startingRow = 0
            if section < startingRows.count {
                startingRow = startingRows[section]
            }
            observedLazySeq.subscribeTableView(tableView: self, startingIndex: startingRow, section: section + startingSection)
        }
    }
}

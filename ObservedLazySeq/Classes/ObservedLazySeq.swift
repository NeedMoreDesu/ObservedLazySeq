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
    public private(set) var objs: GeneratedSeq<GeneratedSeq<Type>>
    
    public var willChangeContent: (() -> Void)?
    public var didChangeContent: (() -> Void)?
    
    public var insertRowFn: ((_ row:Int, _ section: Int) -> Void)?
    public var deleteRowFn: ((_ row:Int, _ section: Int) -> Void)?
    public var updateRowFn: ((_ row:Int, _ section: Int) -> Void)?

    public var insertSectionFn: ((_ section: Int) -> Void)?
    public var deleteSectionFn: ((_ section: Int) -> Void)?

    public var fullReloadFn: (() -> Void)?
    
    public init(strongRefs: [AnyObject], objs: GeneratedSeq<GeneratedSeq<Type>>) {
        self.strongRefs = strongRefs
        self.objs = objs
    }
    
    public func map<ReturnType>(_ transform: @escaping (Type) -> ReturnType, noStore: Bool = false) -> ObservedLazySeq<ReturnType> {
        let objs = self.objs.map { (row) -> GeneratedSeq<ReturnType> in
            var generatedSeq = row.map(transform)
            if !noStore {
                generatedSeq = generatedSeq.lazySeq()
            }
            return generatedSeq
        }.lazySeq()
        let observed = ObservedLazySeq<ReturnType>(strongRefs: self.strongRefs, objs: objs)
        self.subscribeDefault(observed: observed)
        return observed
    }
    
    public func subscribeDefault<ResultType>(observed: ObservedLazySeq<ResultType>) {
        self.willChangeContent = {
            observed.willChangeContent?()
        }
        self.didChangeContent = {
            observed.didChangeContent?()
        }

        self.insertRowFn = { row, section in
            (self.objs[section] as? LazySeq)?.resetStorage()
            observed.insertRowFn?(row, section)
        }
        self.deleteRowFn = { row, section in
            (self.objs[section] as? LazySeq)?.resetStorage()
            observed.deleteRowFn?(row, section)
        }
        self.updateRowFn = { row, section in
            (self.objs[section] as? LazySeq)?.resetStorage()
            observed.updateRowFn?(row, section)
        }

        self.insertSectionFn = { section in
            (self.objs as? LazySeq)?.resetStorage()
            observed.insertSectionFn?(section)
        }
        self.deleteSectionFn = { section in
            (self.objs as? LazySeq)?.resetStorage()
            observed.deleteSectionFn?(section)
        }

        self.fullReloadFn = {
            (self.objs as? LazySeq)?.resetStorage()
            observed.fullReloadFn?()
        }
    }
    
    public func subscribeTableView(tableViewGetter: @escaping (() -> UITableView?), startingRows: [Int] = [], startingSection: Int = 0) {
        self.willChangeContent = {
            tableViewGetter()?.beginUpdates()
        }
        self.insertRowFn = { row, section in
            (self.objs[section] as? LazySeq)?.resetStorage()
            var startingRow = 0
            if section < startingRows.count {
                startingRow = startingRows[section]
            }
            tableViewGetter()?.insertRows(at: [IndexPath.init(row: row + startingRow, section: section + startingSection)], with: .automatic)
        }
        self.deleteRowFn = { row, section in
            (self.objs[section] as? LazySeq)?.resetStorage()
            var startingRow = 0
            if section < startingRows.count {
                startingRow = startingRows[section]
            }
            tableViewGetter()?.deleteRows(at: [IndexPath.init(row: row + startingRow, section: section + startingSection)], with: .fade)
        }
        self.updateRowFn = { row, section in
            (self.objs[section] as? LazySeq)?.resetStorage()
            var startingRow = 0
            if section < startingRows.count {
                startingRow = startingRows[section]
            }
            tableViewGetter()?.reloadRows(at: [IndexPath.init(row: row + startingRow, section: section + startingSection)], with: .automatic)
        }
        self.insertSectionFn = { section in
            (self.objs as? LazySeq)?.resetStorage()
            tableViewGetter()?.insertSections([section + startingSection], with: .automatic)
        }
        self.deleteSectionFn = { section in
            (self.objs as? LazySeq)?.resetStorage()
            tableViewGetter()?.deleteSections([section + startingSection], with: .fade)
        }
        self.fullReloadFn = {
            tableViewGetter()?.reloadData()
        }
        self.didChangeContent = {
            tableViewGetter()?.endUpdates()
        }
    }
}


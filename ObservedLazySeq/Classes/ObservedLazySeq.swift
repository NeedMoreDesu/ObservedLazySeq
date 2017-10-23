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
    
    public var applyChangesFn:((_ deletions: [IndexPath], _ insertions: [IndexPath], _ updates: [IndexPath], _ sectionDeletions: [Int], _ sectionInsertions: [Int]) -> Void)?
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
        self.fullReloadFn = {
            (self.objs as? LazySeq)?.resetStorage()
            observed.fullReloadFn?()
        }
        
        self.applyChangesFn = { deletions, insertions, updates, sectionDeletions, sectionInsertions in
            (self.objs as? LazySeq)?.resetStorage()
            observed.applyChangesFn?(deletions, insertions, updates, sectionDeletions, sectionInsertions)
        }
    }
    
    public func subscribeTableView(tableViewGetter: @escaping (() -> UITableView?), startingRows: [Int] = [], startingSection: Int = 0) {
        func startingRowForSection(_ section: Int) -> Int {
            if section < startingRows.count {
                return startingRows[section]
            }
            return 0
        }
        func mapIndexPaths(_ indexPaths: [IndexPath]) -> [IndexPath] {
            return indexPaths.map({ (indexPath) -> IndexPath in
                let section = indexPath.section + startingSection
                let row = indexPath.row + startingRowForSection(section)
                return IndexPath(row: row, section: section)
            })
        }
        func mapSections(_ sections: [Int]) -> [Int] {
            return sections.map({ (section) -> Int in
                return section + startingSection
            })
        }
        
        self.fullReloadFn = {
            (self.objs as? LazySeq)?.resetStorage()
            tableViewGetter()?.reloadData()
        }
        self.applyChangesFn = { deletions, insertions, updates, sectionDeletions, sectionInsertions in
            guard let tableView = tableViewGetter() else {
                return
            }
            (self.objs as? LazySeq)?.resetStorage()
            
            let deletions = mapIndexPaths(deletions)
            let insertions = mapIndexPaths(insertions)
            let updates = mapIndexPaths(updates)
            let sectionDeletions = mapSections(sectionDeletions)
            let sectionInsertions = mapSections(sectionInsertions)

            tableView.beginUpdates()
            tableView.insertSections(IndexSet(sectionInsertions), with: .automatic)
            tableView.deleteSections(IndexSet(sectionDeletions), with: .fade)
            tableView.deleteRows(at: deletions, with: .fade)
            tableView.insertRows(at: insertions, with: .automatic)
            tableView.reloadRows(at: updates, with: .automatic)
            tableView.endUpdates()
        }
    }
}


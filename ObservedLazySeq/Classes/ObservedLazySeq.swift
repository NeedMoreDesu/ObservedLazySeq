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
        let observed = ObservedLazySeq<ReturnType>(strongRefs: self.strongRefs + [self], objs: objs)
        self.subscribeDefault(observed: observed)
        return observed
    }
    
    public func subscribeDefault<ResultType>(observed: ObservedLazySeq<ResultType>) {
        self.fullReloadFn = { [weak self] in
            guard let `self` = self else {
                return
            }

            (self.objs as? LazySeq)?.resetStorage()
            observed.fullReloadFn?()
        }
        
        self.applyChangesFn = { [weak self] deletions, insertions, updates, sectionDeletions, sectionInsertions in
            guard let `self` = self else {
                return
            }
            self.updateObjs(deletions: deletions,
                            insertions: insertions,
                            updates: updates,
                            sectionDeletions: sectionDeletions,
                            sectionInsertions: sectionInsertions)
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
        
        self.fullReloadFn = { [weak self] in
            guard let `self` = self else {
                return
            }

            (self.objs as? LazySeq)?.resetStorage()
            tableViewGetter()?.reloadData()
        }
        self.applyChangesFn = { [weak self] deletions, insertions, updates, sectionDeletions, sectionInsertions in
            guard let tableView = tableViewGetter() else {
                return
            }
            guard let `self` = self else {
                return
            }
            
            let objsCounts0 = self.objs.allObjects().map({$0.count})
            self.updateObjs(deletions: deletions,
                             insertions: insertions,
                             updates: updates,
                             sectionDeletions: sectionDeletions,
                             sectionInsertions: sectionInsertions)
            let objsCounts1 = self.objs.allObjects().map({$0.count})
            (self.objs as? LazySeq)?.resetStorage()
            let objsCounts2 = self.objs.allObjects().map({$0.count})
            if objsCounts1 != objsCounts2 {
                print("deletions: \(deletions), insertions: \(insertions), updates: \(updates), sectionDeletions: \(sectionDeletions), sectionInsertions: \(sectionInsertions)")
                print("objc count 0: \(objsCounts0)")
                print("objc count 1: \(objsCounts1)")
                print("objc count 2: \(objsCounts2)")
            }

            let mappedDeletions = mapIndexPaths(deletions)
            let mappedInsertions = mapIndexPaths(insertions)
            let mappedUpdates = mapIndexPaths(updates)
            let mappedSectionDeletions = mapSections(sectionDeletions)
            let mappedSectionInsertions = mapSections(sectionInsertions)


            tableView.beginUpdates()
            tableView.deleteSections(IndexSet(mappedSectionDeletions), with: .fade)
            tableView.insertSections(IndexSet(mappedSectionInsertions), with: .automatic)
            tableView.deleteRows(at: mappedDeletions, with: .fade)
            tableView.insertRows(at: mappedInsertions, with: .automatic)
            tableView.reloadRows(at: mappedUpdates, with: .automatic)
            tableView.endUpdates()
        }
    }
    
    private func updateObjs(deletions: [IndexPath], insertions: [IndexPath], updates: [IndexPath], sectionDeletions: [Int], sectionInsertions: [Int]) {
        guard let objs = self.objs as? LazySeq else {
            return // nothing is saved anyway
        }
        let deletionsGrouped = Dictionary.init(grouping: deletions, by: { (indexPath) -> Int in
            return indexPath.section
        })
        let insertionsGrouped = Dictionary.init(grouping: insertions, by: { (indexPath) -> Int in
            return indexPath.section
        })
        let updatesGrouped = Dictionary.init(grouping: updates, by: { (indexPath) -> Int in
            return indexPath.section
        })
        
        for (sectionIdx, section) in objs.storage {
            guard let section = section as? LazySeq else {
                continue
            }
            if let _ = sectionDeletions.first(where: { $0 == sectionIdx}) {
                continue
            }
            let deletions = deletionsGrouped[sectionIdx]?.map({ $0.row }) ?? []
            let insertions = insertionsGrouped[sectionIdx]?.map({ $0.row }) ?? []
            let updates = updatesGrouped[sectionIdx]?.map({ $0.row }) ?? []
            if deletions.count == 0 && insertions.count == 0 && updates.count == 0 {
                continue
            }
            section.applyChanges(deletions: deletions, insertions: insertions, updates: updates)
        }
        let generator = objs.generatedSeq()
        objs.applyChanges(deletions: sectionDeletions, insertions: sectionInsertions, updates: [], copyFn: { (oldIndex, newIndex, seq) -> GeneratedSeq<Type>? in
            if oldIndex == newIndex {
                return seq
            }
//            if let oldLazySeq = seq as? LazySeq<Type>,
//                let newLazySeq = generator.get(newIndex) as? LazySeq<Type> {
//                // need to copy stored items, not the generator itself
//                newLazySeq.storage = oldLazySeq.storage
//                return newLazySeq
//            }
            return nil // oh, you are not LazySeq? Then nothing of value was lost
        })
    }
}


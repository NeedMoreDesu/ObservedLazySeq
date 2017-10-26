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
    public private(set) var objs: Type
    
    public var applyChangesFn:((_ deletions: [IndexPath], _ insertions: [IndexPath], _ updates: [IndexPath], _ sectionDeletions: [Int], _ sectionInsertions: [Int]) -> Void)?
    public var fullReloadFn: (() -> Void)?
    
    public init(strongRefs: [AnyObject], objs: Type) {
        self.strongRefs = strongRefs
        self.objs = objs
    }
}

extension ObservedLazySeq where Type: Collection {
    public typealias Type1d = Type.Element
    func getItem(idx: Int) -> Type1d {
        let index = self.objs.index(self.objs.startIndex, offsetBy: numericCast(idx))
        let item = self.objs[index]
        
        return item
    }
    
    func count() -> Int {
        return numericCast(self.objs.count)
    }
}

extension ObservedLazySeq where Type: Collection, Type.Element: Collection {
    public typealias Type2d = Type1d.Element
    func getItem(row: Int, section: Int) -> Type2d {
        let section = self.getItem(idx: section)
        let rowIndex = section.index(section.startIndex, offsetBy: numericCast(row))
        let item = section[rowIndex]
        
        return item
    }
    
    func columns() -> Int {
        return self.count()
    }
    
    func rows(section: Int) -> Int {
        return numericCast(self.getItem(idx: section).count)
    }
}


extension ObservedLazySeq where Type: Collection, Type.Element: Collection {
    public func getItemAt(_ indexPath: IndexPath) -> Type2d {
        return self.getItem(row: indexPath.row, section: indexPath.section)
    }
    
    public func map<ReturnType>(_ transform: @escaping (Type2d) -> ReturnType, noStore: Bool = false) -> ObservedLazySeq<GeneratedSeq<GeneratedSeq<ReturnType>>> {
        let objs = self.objs.generatedSeq().map { (row) -> GeneratedSeq<ReturnType> in
            var generatedSeq = row.generatedSeq().map(transform)
            if !noStore {
                generatedSeq = generatedSeq.lazySeq()
            }
            return generatedSeq
            }
        let observed = ObservedLazySeq<GeneratedSeq<GeneratedSeq<ReturnType>>>(strongRefs: [self], objs: objs)
        self.subscribeDefault(observed: observed)
        return observed
    }
    
    public func subscribeDefault<ResultType>(observed: ObservedLazySeq<GeneratedSeq<GeneratedSeq<ResultType>>>) {
        self.fullReloadFn = { [weak self] in
            guard let `self` = self else {
                return
            }
            
            (self.objs as? LazySeq<Type1d>)?.resetStorage()
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
            
            (self.objs as? LazySeq<Type1d>)?.resetStorage()
            tableViewGetter()?.reloadData()
        }
        self.applyChangesFn = { [weak self] deletions, insertions, updates, sectionDeletions, sectionInsertions in
            guard let tableView = tableViewGetter() else {
                return
            }
            guard let `self` = self else {
                return
            }
            
            self.updateObjs(deletions: deletions,
                            insertions: insertions,
                            updates: updates,
                            sectionDeletions: sectionDeletions,
                            sectionInsertions: sectionInsertions)
            
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
        guard let objs = self.objs as? LazySeq<GeneratedSeq<Type2d>> else {
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
            guard let section = section as? LazySeq<Type2d> else {
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
        objs.applyChanges(deletions: sectionDeletions, insertions: sectionInsertions, updates: [], copyFn: { (oldIndex, newIndex, seq) -> GeneratedSeq<Type2d>? in
            if oldIndex == newIndex {
                return seq
            }
            if let oldLazySeq = seq as? LazySeq<Type2d>,
                let newLazySeq = generator.get(newIndex) as? LazySeq<Type2d> {
                // need to copy stored items, not the generator itself
                newLazySeq.storage = oldLazySeq.storage
                return newLazySeq
            }
            return nil // oh, you are not LazySeq? Then nothing of value was lost
        })
    }
}


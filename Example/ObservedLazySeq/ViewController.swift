//
//  ViewController.swift
//  ObservedLazySeq
//
//  Created by Oleksii Horishnii on 10/13/2017.
//  Copyright (c) 2017 Oleksii Horishnii. All rights reserved.
//

import UIKit
import ObservedLazySeq
import LazySeq

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    struct CellModel {
        var cellTitle: String
        var deleteCellFn: (() -> Void)
    }
    
    struct SectionModel {
        var sectionTitle: String
    }

    @IBOutlet weak var tableView: UITableView!
    weak var tableViewWeUse: UITableView!

    var oldObserved: ObservedLazySeq<Timestamp>!
    var observed: ObservedLazySeq<CellModel>! {
        didSet {
            self.observed.subscribeTableView(tableViewGetter: { [weak self] () -> UITableView? in
                return self?.tableViewWeUse // count be self?.tableView, but we explicitly show that we don't care if tableView is here at this moment, since we take it from `self` directly
            })
            self.tableView?.reloadData()
        }
    }
    var sectionModels: GeneratedSeq<SectionModel>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let observedSectionsOriginal = Timestamp.createObservedLazySeq()
        self.oldObserved = observedSectionsOriginal
        self.sectionModels = observedSectionsOriginal.objs.map({ (section) -> SectionModel in
//            print("sectionmodel generate")
            let second = section.first()?.second ?? 0
            let sectionModel = SectionModel(sectionTitle: "\(second)s")
            return sectionModel
        })
        self.observed = observedSectionsOriginal.map({ (timestamp) -> CellModel in
//            print("cellmodel generate")
            let cellModel = CellModel(cellTitle: "\(timestamp.time!)", deleteCellFn: {
                timestamp.delete()
            })
            return cellModel
        })
        
        // oops, our tableView is loaded after observedSections is being set
        // but because tableView is passed as getter, it's no big deal
        self.tableViewWeUse = self.tableView
        
        self.generateTimestampEvery1sec()
    }

    func generateTimestampEvery1sec() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
            let _ = Timestamp.create()
            CoreData.shared.save()
            
            self?.generateTimestampEvery1sec()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.observed.objs.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.observed.objs[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = self.observed.objs[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "main", for: indexPath)
        
        cell.textLabel?.text = cellModel.cellTitle
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionModel = self.sectionModels.get(section)
        return sectionModel?.sectionTitle ?? "unknown"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel = self.observed.objs[indexPath.section][indexPath.row]
        cellModel.deleteCellFn()
    }
}


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
    @IBOutlet weak var tableView: UITableView!
    weak var tableViewWeUse: UITableView!

    var observedSections: LazySeq<ObservedLazySeq<Timestamp>>! {
        didSet {
            self.observedSections.subscribeTableViewToObservedSections(tableViewGetter: { [weak self] () -> UITableView? in
                return self?.tableViewWeUse // count be self?.tableView, but we explicitly show that we don't care if tableView is here at this moment, since we take it from `self` directly
            })
            self.tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.observedSections = Timestamp.createObservedLazySeq()
        // oops, our tableView is loaded after observedSections is being set
        // but because tableView is passed as getter, it's no big deal
        self.tableViewWeUse = self.tableView
        
        self.generateTimestampEvery2sec()
    }

    func generateTimestampEvery2sec() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { [weak self] in
            let _ = Timestamp.create()
            CoreData.shared.save()
            
            self?.generateTimestampEvery2sec()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.observedSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.observedSections[section].objs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let timestamp = self.observedSections[indexPath.section].objs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "main", for: indexPath)
        
        cell.textLabel?.text = "\(timestamp.time!)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timestamp = self.observedSections[indexPath.section].objs[indexPath.row]
        timestamp.delete()
    }
}


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

class FirstScreenVC: UIViewController, FirstScreenView, UITableViewDelegate, UITableViewDataSource {
    //MARK:- outlets
    @IBOutlet private weak var tableView: UITableView!

    //MARK:- FirstScreenView Interface
    var presenter: FirstScreenPresenter!

    var observed: ObservedLazySeq<FirstScreenCellModel>! {
        didSet {
            self.observed.subscribeTableView(tableViewGetter: { [weak self] () -> UITableView? in
                return self?.tableView // we explicitly show that we don't care if tableView is here at this moment, since we take it from `self` directly
            })
        }
    }
    var sectionModels: GeneratedSeq<FirstScreenSectionModel>!

    //MARK:- table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.observed.objs.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.observed.objs[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = self.observed.getItemAt(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "main", for: indexPath)
        
        cell.textLabel?.text = cellModel.cellTitle
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionModel = self.sectionModels[section]
        return sectionModel.sectionTitle
    }
    
    //MARK:- table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.presenter.cellClickedAt(indexPath: indexPath)
    }
}


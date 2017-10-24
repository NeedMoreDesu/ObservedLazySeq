//
//  FirstScreenRouter.swift
//  ObservedLazySeq_Example
//
//  Created by Oleksii Horishnii on 10/24/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Swinject
import SwinjectStoryboard

class ApplicationStartWireframe: ApplicationStartRouter {
    var container: Container = DependencyInjection.shared.container
    func showFirstScreen() {
        let vc = self.container.resolve(FirstScreenView.self)!
        vc.presenter = self.container.resolve(FirstScreenPresenter.self)
        vc.presenter.view = vc
        AppDelegate.shared.window?.rootViewController = vc as? UIViewController
    }
}

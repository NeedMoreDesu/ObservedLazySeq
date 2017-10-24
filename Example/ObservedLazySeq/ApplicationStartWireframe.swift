//
//  FirstScreenRouter.swift
//  ObservedLazySeq_Example
//
//  Created by Oleksii Horishnii on 10/24/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Swinject

class ApplicationStartWireframe: ApplicationStartRouter {
    var container: Container = DependencyInjection.shared.container
    func showFirstScreen() {
        let vc = self.container.resolve(FirstScreenView.self)!
        AppDelegate.shared.window?.rootViewController = vc as? UIViewController
    }
}

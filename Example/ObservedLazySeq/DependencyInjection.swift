//
//  Swinject.swift
//  ObservedLazySeq_Example
//
//  Created by Oleksii Horishnii on 10/24/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Swinject

struct DependencyInjection {
    public static let shared = DependencyInjection()

    public let container: Container

    init(container: Container = Container()) {
        self.container = container
    }
    
    func resolve<Type>() -> Type {
        return self.container.resolve(Type.self)!
    }
    
    func setup() {
        self.setupRouters()
        self.setupViews()
        self.setupPresenters()
        self.setupUseCases()
        self.setupRepositories()
    }
    
    func setupRouters() {
        self.container.register(ApplicationStartRouter.self) { (_) -> ApplicationStartRouter in
            return ApplicationStartWireframe()
        }
    }
    
    func setupViews() {
        self.container.register(FirstScreenView.self) { (r) -> FirstScreenView in
            let vc: FirstScreenView = Storyboards.main.getVC()
            
            vc.presenter = r.resolve(FirstScreenPresenter.self)
            vc.presenter.view = vc
            
            return vc
        }
    }
    
    func setupPresenters() {
        self.container.register(FirstScreenPresenter.self) { (r) -> FirstScreenPresenter in
            let presenter = FirstScreenPresenterImplementation()
            
            presenter.useCase = r.resolve(FirstScreenUseCase.self)
            presenter.useCase.output = presenter
            
            return presenter
        }
    }
    
    func setupUseCases() {
        self.container.register(FirstScreenUseCase.self) { (r) -> FirstScreenUseCase in
            let useCase = FisrtScreenInteractor()
            
            useCase.timestampRouter = r.resolve(TimestampRouter.self)
            
            return useCase
        }
    }
    
    func setupRepositories() {
        self.container.register(TimestampRouter.self) { (_) -> TimestampRouter in
            return TimestampGateway()
        }
    }
}


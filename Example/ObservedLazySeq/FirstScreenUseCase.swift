//
//  FirstScreenUseCase.swift
//  ObservedLazySeq_Example
//
//  Created by Oleksii Horishnii on 10/24/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import LazySeq
import ObservedLazySeq

struct Seconds {
    let value: Int
}

protocol FirstScreenOutput: class {
    // could map it to something else, but Timestamp is so simple..
    var observed: ObservedLazySeq<GeneratedSeq<GeneratedSeq<Timestamp>>>! { get set }
    var sectionSeconds: GeneratedSeq<Seconds>! { get set }
}

protocol TimestampRouter {
    func createTimestamp() -> Timestamp
    func observed() -> ObservedLazySeq<GeneratedSeq<GeneratedSeq<Timestamp>>>
    func sectionSeconds() -> GeneratedSeq<Seconds>
    func deleteTimestampAt(indexPath: IndexPath)
}

protocol FirstScreenUseCase: class {
    weak var output: FirstScreenOutput! { get set }
    var timestampRouter: TimestampRouter! { get set }
    
    func deleteItemAt(indexPath: IndexPath)
}

class FisrtScreenInteractor: FirstScreenUseCase {
    var timestampRouter: TimestampRouter!
    weak var output: FirstScreenOutput! { didSet { self.setup() } }
    
    func setup() {
        output.observed = self.timestampRouter.observed()
        output.sectionSeconds = self.timestampRouter.sectionSeconds()
        self.generateTimestampEvery1sec()
    }

    func deleteItemAt(indexPath: IndexPath) {
        self.timestampRouter.deleteTimestampAt(indexPath: indexPath)
    }
    
    func generateTimestampEvery1sec() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
            let _ = self?.timestampRouter.createTimestamp()
            self?.generateTimestampEvery1sec()
        }
    }
}

//
//  Storyboards.swift
//  ObservedLazySeq_Example
//
//  Created by Oleksii Horishnii on 10/24/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

struct Storyboards {
    static let main = UIStoryboard(name: "Main", bundle: nil)
}

extension UIStoryboard {
    func getVC<VC>(identifier: String? = nil) -> VC {
        if let id = identifier {
            return self.instantiateViewController(withIdentifier: id) as! VC
        } else {
            return self.instantiateInitialViewController() as! VC
        }
    }
}

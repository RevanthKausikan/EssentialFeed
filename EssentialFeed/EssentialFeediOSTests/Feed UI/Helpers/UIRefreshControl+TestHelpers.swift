//
//  UIRefreshControl+TestHelpers.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?
                .forEach { (target as NSObject).perform(Selector($0)) }
        }
    }
}

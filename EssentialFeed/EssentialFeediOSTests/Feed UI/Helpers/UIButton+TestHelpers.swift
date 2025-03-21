//
//  UIButton+TestHelpers.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import UIKit

extension UIButton {
    func simulateTap() {
        simulate(event: .touchUpInside)
    }
}

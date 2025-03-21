//
//  UITableView+Dequeueing.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        return dequeueReusableCell(withIdentifier: identifier) as! T
    }
}

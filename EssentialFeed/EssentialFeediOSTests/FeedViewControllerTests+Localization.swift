//
//  FeedViewControllerTests+Localization.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import Foundation
import Testing
import EssentialFeediOS

extension FeedViewControllerTests {
    func localized(_ key: String, fileID: String = #fileID, filePath: String = #filePath,
                           line: Int = #line, column: Int = #column) throws -> String {
        let table = "Feed"
        let bundle = Bundle(for: FeedViewController.self)
        let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)
        try #require(localizedString != key,
                     sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return localizedString
    }
}

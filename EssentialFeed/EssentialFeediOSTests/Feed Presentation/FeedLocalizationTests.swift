//
//  FeedLocalizationTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//


import Testing
import Foundation
@testable import EssentialFeediOS

struct FeedLocalizationTests {
    @Test("Localized strings - have keys and values for all supported localizations")
    func localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Feed"
        let presentationBundle = Bundle(for: FeedPresenter.self)
        let localizationBundles = allLocalizationBundles(in: presentationBundle)
        let localizedStringKeys = allLocalizedStringKeys(in: localizationBundles, table: table)
        
        localizationBundles.forEach { (bundle, localization) in
            localizedStringKeys.forEach { key in
                let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)
                
                if localizedString == key {
                    let language = Locale.current.localizedString(forLanguageCode: localization) ?? ""
                    
                    Issue.record("Missing \(language) (\(localization)) localized string for key: '\(key)' in table: '\(table)'")
                }
            }
        }
    }
}

// MARK: - Helpers
extension FeedLocalizationTests {
    private typealias LocalizedBundle = (bundle: Bundle, localization: String)
    
    private func allLocalizationBundles(in bundle: Bundle, fileID: String = #fileID, filePath: String = #filePath,
                                        line: Int = #line, column: Int = #column) -> [LocalizedBundle] {
        return bundle.localizations.compactMap { localization in
            guard
                let path = bundle.path(forResource: localization, ofType: "lproj"),
                let localizedBundle = Bundle(path: path)
            else {
                Issue.record("Couldn't find bundle for localization: \(localization)",
                             sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                return nil
            }
            
            return (localizedBundle, localization)
        }
    }
    
    private func allLocalizedStringKeys(in bundles: [LocalizedBundle], table: String,
                                        fileID: String = #fileID, filePath: String = #filePath,
                                        line: Int = #line, column: Int = #column) -> Set<String> {
        return bundles.reduce([]) { (acc, current) in
            guard
                let path = current.bundle.path(forResource: table, ofType: "strings"),
                let strings = NSDictionary(contentsOfFile: path),
                let keys = strings.allKeys as? [String]
            else {
                Issue.record("Couldn't load localized strings for localization: \(current.localization)",
                             sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                return acc
            }
            
            return acc.union(Set(keys))
        }
    }
}

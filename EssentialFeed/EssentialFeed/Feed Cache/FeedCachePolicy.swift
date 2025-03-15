//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

/// This is a value object without identity as opposed to entities (models with identity).
/// Since its not supposed to change, make it `static` and `private init`.
enum FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    private static let maxCacheAgeInDays = 7
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let macCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return date < macCacheAge
    }
}

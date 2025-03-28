//
//  FeedCacheTestHelpers.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import EssentialFeed

var uniqueImage: FeedImage { .init(id: UUID(), description: "any", location: "any", url: anyURL) }

func getUniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage, uniqueImage]
    let local = models.map {
        LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
    }
    return (models, local)
}

// Cache policy specific helper
extension Date {
    private var feedCacheMaxAgeInDays: Int { 7 }
    
    func minusFeedCacheMaxAge() -> Self {
        adding(days: -feedCacheMaxAgeInDays)
    }
    
    private func adding(days: Int) -> Self {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

extension Date {
    func adding(seconds: TimeInterval) -> Self {
        self + seconds
    }
}

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

extension Date {
    func adding(days: Int) -> Self {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Self {
        self + seconds
    }
}

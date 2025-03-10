//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 07/03/25.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else {
                completion(nil)
                return
            }
            if let error {
                completion(error)
            } else {
                cache(feed, with: completion)
            }
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { error in
            if let error {
                completion(.failure(error))
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.asLocal, timestamp: currentDate()) { [weak self] error in
            guard self != nil else {
                completion(nil)
                return
            }
            completion(error)
        }
    }
}

fileprivate extension Array where Element == FeedImage {
    var asLocal: [LocalFeedImage] {
        map { .init(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

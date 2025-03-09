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
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else {
                completion(nil)
                return
            }
            if let error {
                completion(error)
            } else {
                cache(items, with: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
        store.insert(items.asLocal, timestamp: currentDate()) { [weak self] error in
            guard self != nil else {
                completion(nil)
                return
            }
            completion(error)
        }
    }
}

fileprivate extension Array where Element == FeedItem {
    var asLocal: [LocalFeedItem] {
        map { .init(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    }
}

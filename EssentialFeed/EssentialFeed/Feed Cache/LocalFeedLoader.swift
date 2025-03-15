//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 07/03/25.
//

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionResult in
            guard let self else {
//                completion(nil) // TODO: - To fix this, ideally should not pass this...
                return
            }
            
            switch deletionResult {
            case .success: cache(feed, with: completion)
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.asLocal, timestamp: currentDate()) { [weak self] insertionResult in
            guard self != nil else {
//                completion(nil) // TODO: - To fix this, ideally should not pass this...
                return
            }
            completion(insertionResult)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = FeedLoader.Result
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else {
                completion(.success([])) // TODO: - To fix this, ideally should not pass this...
                return
            }
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(.some(let cache)) where FeedCachePolicy.validate(cache.timestamp, against: currentDate()):
                completion(.success(cache.feed.asModels))
            case .success: completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure: store.deleteCachedFeed { _ in }
            case .success(.some(let cache)) where !FeedCachePolicy.validate(cache.timestamp, against: currentDate()):
                store.deleteCachedFeed { _ in }
            case .success: break
            }
        }
    }
}

fileprivate extension Array where Element == FeedImage {
    var asLocal: [LocalFeedImage] {
        map { .init(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

fileprivate extension Array where Element == LocalFeedImage {
    var asModels: [FeedImage] {
        map { .init(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

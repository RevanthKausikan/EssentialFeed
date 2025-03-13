//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 07/03/25.
//

/// This is a value object without identity as opposed to entities (models with identity).
/// Since its not supposed to change, make it `static` and `private init`.
final class FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    private static let maxCacheAgeInDays = 7
    
    private init() {}
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let macCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return date < macCacheAge
    }
}

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else {
                completion(nil) // TODO: - To fix this, ideally should not pass this...
                return
            }
            if let error {
                completion(error)
            } else {
                cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.asLocal, timestamp: currentDate()) { [weak self] error in
            guard self != nil else {
                completion(nil) // TODO: - To fix this, ideally should not pass this...
                return
            }
            completion(error)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else {
                completion(.success([])) // TODO: - To fix this, ideally should not pass this...
                return
            }
            switch result {
            case .failure(let error): completion(.failure(error))
            case .found(let feed, let timestamp) where FeedCachePolicy.validate(timestamp, against: currentDate()):
                completion(.success(feed.asModels))
            case .found, .empty: completion(.success([]))
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
            case .found(_, let timestamp) where !FeedCachePolicy.validate(timestamp, against: currentDate()):
                store.deleteCachedFeed { _ in }
            case .found, .empty: break
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

//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import Testing
import EssentialFeed

final class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            .init(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletions) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let decoder = JSONDecoder()
        let cached = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cached.localFeed, timestamp: cached.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletions) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests {
    
    init() {
        let storeURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    deinit {
        let storeURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    @Test("Retrieve delivers empty cache on empty store")
    func retrieve_deliversEmptyCacheOnEmptyStore() async {
        let sut = CodableFeedStore()
        
        await withCheckedContinuation { continuation in
            sut.retrieve { result in
                switch result {
                case .empty: break
                default: Issue.record("Expected empty result, got \(result)")
                }
                continuation.resume()
            }
        }
    }
    
    @Test("Retrieve has no side effect on empty cache")
    func retrieve_hasNoSideEffectOnEmptyCache() async {
        let sut = CodableFeedStore()
        
        await withCheckedContinuation { continuation in
            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                    case (.empty, .empty): break
                    default: Issue.record("Expected empty result, got \(firstResult) and \(secondResult)")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
   @Test("Retrieve after inserting to empty cache delivers inserted values")
    func retrieve_afterInsertingToEmptyCacheDeliveresInsertedValues() async {
        let sut = CodableFeedStore()
        let feed = getUniqueImageFeed().local
        let timestamp = Date()
        
        await withCheckedContinuation { continuation in
            sut.insert(feed, timestamp: timestamp) { insertionError in
                switch insertionError {
                case .none: break
                default: Issue.record("Expected successful insertion, got \(String(describing: insertionError))")
                }
                
                sut.retrieve { retrieveResult in
                    switch retrieveResult {
                    case let .found(retrievedFeed, retrievedTimestamp):
                        #expect(retrievedFeed == feed)
                        #expect(retrievedTimestamp == timestamp)
                    default: Issue.record("Expected found result with \(feed) and \(timestamp), got \(retrieveResult) instead.")
                    }
                    continuation.resume()
                }
            }
        }
    }
}

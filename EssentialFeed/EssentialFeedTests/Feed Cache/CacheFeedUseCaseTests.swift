//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 07/03/25.
//

import Testing
import Foundation
import EssentialFeed

final class FeedStore {
    var deleteCachedFeedCallCount = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
}

struct LocalFeedLoader {
    let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

struct CacheFeedUseCaseTests {

    @Test("Init doesn't delete cache upon creation")
    func init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        
        #expect(store.deleteCachedFeedCallCount == 0)
    }
    
    @Test("Save requests cache deletion")
    func save_requestsCacheDeletion() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        let items = [uniqueItem, uniqueItem]
        sut.save(items)
        
        #expect(store.deleteCachedFeedCallCount == 1)
    }
}

// MARK: - Helpers
extension CacheFeedUseCaseTests {
    private var uniqueItem: FeedItem {
        .init(id: UUID(), description: "any", location: "any", imageURL: anyURL)
    }
    
    private var anyURL: URL { URL(string: "any-url.com")! }
}

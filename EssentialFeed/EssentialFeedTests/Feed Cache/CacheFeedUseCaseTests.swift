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

final class LocalFeedLoader {
    let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

final class CacheFeedUseCaseTests: EFTesting {

    @Test("Init doesn't delete cache upon creation")
    func init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        #expect(store.deleteCachedFeedCallCount == 0)
    }
    
    @Test("Save requests cache deletion")
    func save_requestsCacheDeletion() {
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT()
        
        sut.save(items)
        
        #expect(store.deleteCachedFeedCallCount == 1)
    }
}

// MARK: - Helpers
extension CacheFeedUseCaseTests {
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        trackForMemoryLeak(store, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        
        return (sut, store)
    }
    
    private var uniqueItem: FeedItem {
        .init(id: UUID(), description: "any", location: "any", imageURL: anyURL)
    }
    
    private var anyURL: URL { URL(string: "any-url.com")! }
}

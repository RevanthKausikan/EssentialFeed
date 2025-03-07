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
    typealias DeletionCompletions = (NSError?) -> Void
    
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    var deletionCompletions = [DeletionCompletions]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletions) {
        deleteCachedFeedCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: NSError, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem]) {
        insertCallCount += 1
    }
}

final class LocalFeedLoader {
    let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                store.insert(items)
            }
        }
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
    
    @Test("Save does not request cache insertion on deletion error")
    func save_doesNotRequestCacheInsertion_onDeletionError() {
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT()
        let deletionError = anyError
        
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        #expect(store.insertCallCount == 0)
    }
    
    @Test("Save requests new cache insertion on successful deletion")
    func save_requestsNewCacheInsertion_onSuccessfulDeletion() {
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT()
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        #expect(store.insertCallCount == 1)
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
    private var anyError: NSError { NSError(domain: "any error", code: 1) }
}

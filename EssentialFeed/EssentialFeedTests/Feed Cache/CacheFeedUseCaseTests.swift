//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 07/03/25.
//

import Testing
import Foundation
import EssentialFeed

final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                store.insert(items, timestamp: currentDate())
            }
        }
    }
}

final class FeedStore {
    typealias DeletionCompletions = (NSError?) -> Void
    
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    var deletionCompletions = [DeletionCompletions]()
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    
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
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        insertCallCount += 1
        insertions.append((items, timestamp))
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
    
    @Test("Save requests new cache insertion with timestamp on successful deletion")
    func save_requestsNewCacheInsertionWithTimestamp_onSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        #expect(store.insertions.count == 1)
        #expect(store.insertions.first?.items == items)
        #expect(store.insertions.first?.timestamp == timestamp)
    }
}

// MARK: - Helpers
extension CacheFeedUseCaseTests {
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
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

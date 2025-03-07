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
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                store.insert(items, timestamp: currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

final class FeedStore {
    typealias DeletionCompletions = (Error?) -> Void
    typealias InsertionCompletions = (Error?) -> Void
    
    var deletionCompletions = [DeletionCompletions]()
    var insertionCompletions = [InsertionCompletions]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletions) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletions) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(items, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}

final class CacheFeedUseCaseTests: EFTesting {
    
    @Test("Init doesn't message store upon creation")
    func init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        #expect(store.receivedMessages == [])
    }
    
    @Test("Save requests cache deletion")
    func save_requestsCacheDeletion() {
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT()
        
        sut.save(items) { _ in }
        
        #expect(store.receivedMessages == [.deleteCachedFeed])
    }
    
    @Test("Save does not request cache insertion on deletion error")
    func save_doesNotRequestCacheInsertion_onDeletionError() {
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT()
        let deletionError = anyError
        
        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)
        
        #expect(store.receivedMessages == [.deleteCachedFeed])
    }
    
    @Test("Save requests new cache insertion with timestamp on successful deletion")
    func save_requestsNewCacheInsertionWithTimestamp_onSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        #expect(store.receivedMessages == [.deleteCachedFeed, .insert(items, timestamp)])
    }
    
    @Test("Save fails on deletion error")
    func save_fails_onDeletionError() async {
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT()
        let deletionError = anyError
        
        let capturedError = await withCheckedContinuation { continuation in
            sut.save(items) { error in
                continuation.resume(returning: error)
            }
            store.completeDeletion(with: deletionError)
        }
        
        #expect(capturedError as? NSError == deletionError)
    }
    
    @Test("Save fails on insertion error")
    func save_fails_onInsertionError() async {
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT()
        let insertionError = anyError
        
        let capturedError = await withCheckedContinuation { continuation in
            sut.save(items) { error in
                continuation.resume(returning: error)
            }
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
        
        #expect(capturedError as? NSError == insertionError)
    }
    
    @Test("Save succeeds on successful cache insertion")
    func save_succeeds_onSuccessfulCacheInsertion() async {
        let items = [uniqueItem, uniqueItem]
        let (sut, store) = makeSUT()
        
        let capturedError = await withCheckedContinuation { continuation in
            sut.save(items) { error in
                continuation.resume(returning: error)
            }
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
        
        #expect(capturedError == nil)
    }
}

// MARK: - Helpers
extension CacheFeedUseCaseTests {
    private var uniqueItem: FeedItem { .init(id: UUID(), description: "any", location: "any", imageURL: anyURL) }
    private var anyURL: URL { URL(string: "any-url.com")! }
    private var anyError: NSError { NSError(domain: "any error", code: 1) }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        trackForMemoryLeak(store, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        
        return (sut, store)
    }
}

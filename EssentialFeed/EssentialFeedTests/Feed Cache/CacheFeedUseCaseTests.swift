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
    
    func save(_ items: [FeedItem], completion: @escaping (NSError?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            completion(error)
            if error == nil {
                store.insert(items, timestamp: currentDate())
            }
        }
    }
}

final class FeedStore {
    typealias DeletionCompletions = (NSError?) -> Void
    
    var deletionCompletions = [DeletionCompletions]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletions) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: NSError, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items, timestamp))
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
        
        #expect(capturedError == deletionError)
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

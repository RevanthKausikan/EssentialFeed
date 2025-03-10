//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 10/03/25.
//

import Testing
import Foundation
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: EFTesting {
    @Test("Init doesn't message store upon creation")
    func init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        #expect(store.receivedMessages == [])
    }
}

// MARK: - Helpers
extension LoadFeedFromCacheUseCaseTests {
    private typealias CacheFeedUseCaseTestsSUT = (sut: LocalFeedLoader, store: FeedStoreSpy)
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> CacheFeedUseCaseTestsSUT {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        trackForMemoryLeak(store, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        
        return (sut, store)
    }
}

fileprivate final class FeedStoreSpy: FeedStore {
    typealias DeletionCompletions = (Error?) -> Void
    typealias InsertionCompletions = (Error?) -> Void
    
    var deletionCompletions = [DeletionCompletions]()
    var insertionCompletions = [InsertionCompletions]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
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
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletions) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}

//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 07/03/25.
//

import Testing
import EssentialFeed

final class CacheFeedUseCaseTests: EFTesting {
    
    @Test("Init doesn't message store upon creation")
    func init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        #expect(store.receivedMessages == [])
    }
    
    @Test("Save requests cache deletion")
    func save_requestsCacheDeletion() {
        let feed = getUniqueImageFeed()
        let (sut, store) = makeSUT()
        
        sut.save(feed.models) { _ in }
        
        #expect(store.receivedMessages == [.deleteCachedFeed])
    }
    
    @Test("Save does not request cache insertion on deletion error")
    func save_doesNotRequestCacheInsertion_onDeletionError() {
        let feed = getUniqueImageFeed()
        let (sut, store) = makeSUT()
        let deletionError = anyError
        
        sut.save(feed.models) { _ in }
        store.completeDeletion(with: deletionError)
        
        #expect(store.receivedMessages == [.deleteCachedFeed])
    }
    
    @Test("Save requests new cache insertion with timestamp on successful deletion")
    func save_requestsNewCacheInsertionWithTimestamp_onSuccessfulDeletion() {
        let timestamp = Date()
        let feed = getUniqueImageFeed()
        
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(feed.models) { _ in }
        store.completeDeletionSuccessfully()
        
        #expect(store.receivedMessages == [.deleteCachedFeed, .insert(feed.local, timestamp)])
    }
    
    @Test("Save fails on deletion error")
    func save_fails_onDeletionError() async {
        let (sut, store) = makeSUT()
        let deletionError = anyError
        
        await expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }
    
    @Test("Save fails on insertion error")
    func save_fails_onInsertionError() async {
        let (sut, store) = makeSUT()
        let insertionError = anyError
        
        await expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }
    
    @Test("Save succeeds on successful cache insertion")
    func save_succeeds_onSuccessfulCacheInsertion() async {
        let (sut, store) = makeSUT()
        
        await expect(sut, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }
    
    @Test("Save does not deliver deletion error when the instance is deallocated",
          .disabled("Testing should be equated to nil. Fix the TODOs"),
          .timeLimit(.minutes(1)))
    func save_doesNotDeliverDeletionError_whenInstancIsDeallocated() async {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        let capturedError: LocalFeedLoader.SaveResult = await withCheckedContinuation { continuation in
            sut?.save(getUniqueImageFeed().models) { error in
                continuation.resume(returning: error)
            }
            
            sut = nil
            store.completeDeletion(with: anyError)
        }
        
        #expect(capturedError == nil)
    }
    
    @Test("Save does not deliver insertion error when the instance is deallocated",
          .disabled("Testing should be equated to nil. Fix the TODOs"),
          .timeLimit(.minutes(1)))
    func save_doesNotDeliverInsertionError_whenInstancIsDeallocated() async {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        let capturedError = await withCheckedContinuation { continuation in
            sut?.save(getUniqueImageFeed().models) { error in
                continuation.resume(returning: error)
            }
            
            store.completeDeletionSuccessfully()
            sut = nil
            store.completeInsertion(with: anyError)
        }
        
        #expect(capturedError == nil)
    }
}

// MARK: - Helpers
extension CacheFeedUseCaseTests {
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
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError receivedError: NSError?,
                        when action: () -> Void, fileID: String = #fileID, filePath: String = #filePath,
                        line: Int = #line, column: Int = #column) async {
        let capturedError: Error? = await withCheckedContinuation { continuation in
            sut.save([uniqueImage]) { result in
                if case let Result.failure(error) = result {
                    continuation.resume(returning: error)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            action()
        }
        
        #expect(capturedError as? NSError == receivedError,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
}

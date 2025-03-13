//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 10/03/25.
//

import Testing
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: EFTesting {
    @Test("Init doesn't message store upon creation")
    func init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        #expect(store.receivedMessages == [])
    }
    
    @Test("Load requests cache retrieval")
    func load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load fails on cache retrieval")
    func load_failsOnCacheRetrieval() async {
        let (sut, store) = makeSUT()
        let retrievalError = anyError
        
        await expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }
    
    @Test("Load delivers no images on empty cache")
    func load_deliversNoImagesOnEmptyCache() async {
        let (sut, store) = makeSUT()
        
        await expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }
    
    @Test("Load delivers cached images on non expired cache")
    func load_deliversCachedImages_onNonExpiredCache() async {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success(feed.models), when: {
            store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        })
    }
    
    @Test("Load delivers no images on cache expiration")
    func load_deliversNoImages_onCacheExpiration() async {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let cacheExpirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: cacheExpirationTimestamp)
        })
    }
    
    @Test("Load delivers cached images on expired cache")
    func load_deliversCachedImages_onExpiredCache() async {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredCacheTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: expiredCacheTimestamp)
        })
    }
    
    @Test("Load has no side effects on retrival error")
    func load_hasNoSideEffects_onRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrieval(with: anyError)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load has no side effects on empty cache")
    func load_hasNoSideEffects_onEmptyCache( ) {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load has no side effects on non expired cache")
    func load_hasNoSideEffects_onNonExpiredCache( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load has no side effects cache expiration")
    func load_hasNoSideEffects_onCacheExpiration( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let cacheExpirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: cacheExpirationTimestamp)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load has no side effect on expired cache")
    func load_hasNoSideEffects_onExpiredCache( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredCacheTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: expiredCacheTimestamp)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load does not deliver results after SUT has been deallocated",
          .disabled("Testing should be equated to nil. Fix the TODOs"))
    func load_doesNotDeliverResults_afterSUTHasBeenDeallocated() async {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        let capturedResult = await withCheckedContinuation { continuation in
            sut?.load { result in
                continuation.resume(returning: result)
            }
            
            sut = nil
            store.completeRetrievalWithEmptyCache()
        }
        
        #expect(capturedResult == nil)
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
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
                        when action: () -> Void, fileID: String = #fileID, filePath: String = #filePath,
                        line: Int = #line, column: Int = #column) async {
        await withCheckedContinuation { continuation in
            sut.load { receivedResult in
                switch (receivedResult, expectedResult) {
                case (.success(let receivedImages), .success(let expectedImages)):
                    #expect(receivedImages == expectedImages,
                            sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                case (.failure(let receivedError), .failure(let expectedError)):
                    #expect(receivedError as NSError == expectedError as NSError,
                            sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                default: Issue.record("Expected \(expectedResult) but got \(receivedResult) instead.",
                                      sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                }
                continuation.resume()
            }
            action()
        }
    }
}

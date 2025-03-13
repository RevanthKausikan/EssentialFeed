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
    
    @Test("Load delivers cached images on < 7 days old cache")
    func load_deliversCachedImages_onLessThanSevenDaysOldCache() async {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success(feed.models), when: {
            store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOld)
        })
    }
    
    @Test("Load delivers no images on 7 days old cache")
    func load_deliversNoImages_onSevenDaysOldCache() async {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOld = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: sevenDaysOld)
        })
    }
    
    @Test("Load delivers cached images on > 7 days old cache")
    func load_deliversCachedImages_onMoreThanSevenDaysOldCache() async {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOld)
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
    
    @Test("Load has no side effects on < 7 days old cache")
    func load_hasNoSideEffects_onLessThanSevenDaysOldCache( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOld)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load deletes cache feed on 7 days old cache")
    func load_deletesCacheFeed_onSevenDaysOldCache( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOld = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: sevenDaysOld)
        
        #expect(store.receivedMessages == [.retrieve, .deleteCachedFeed])
    }
    
    @Test("Load deletes cache feed on > 7 days old cache")
    func load_deletesCacheFeed_onMoreThanSevenDaysOldCache( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: moreThanSevenDaysOld)
        
        #expect(store.receivedMessages == [.retrieve, .deleteCachedFeed])
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
    private var anyURL: URL { URL(string: "any-url.com")! }
    private var anyError: NSError { NSError(domain: "any error", code: 1) }
    private var uniqueImage: FeedImage { .init(id: UUID(), description: "any", location: "any", url: anyURL) }
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
    
    private func getUniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniqueImage, uniqueImage]
        let local = models.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (models, local)
    }
}

fileprivate extension Date {
    func adding(days: Int) -> Self {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Self {
        self + seconds
    }
}

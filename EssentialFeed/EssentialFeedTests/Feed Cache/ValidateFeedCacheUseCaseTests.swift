//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import Testing
import EssentialFeed

final class ValidateFeedCacheUseCaseTests: EFTesting {
    @Test("Init doesn't message store upon creation")
    func init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        #expect(store.receivedMessages == [])
    }
    
    @Test("Validate cache deletes cache feed on retrival error")
    func validateCache_deletesCacheFeed_onRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrieval(with: anyError)
        
        #expect(store.receivedMessages == [.retrieve, .deleteCachedFeed])
    }
    
    @Test("Validate cache does not delete cache feed on empty cache")
    func validateCache_doesNotDeleteCacheFeed_onEmptyCache( ) {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        #expect(store.receivedMessages == [.retrieve])
    }

    @Test("Validate Cache does not delete cache feed on < 7 days old cache")
    func validateCache_doesNotDeleteCacheFeed_onLessThanSevenDaysOldCache( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOld)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    
    @Test("Validate cache deletes cache feed on 7 days old cache")
    func validateCache_deletesCacheFeed_onSevenDaysOldCache( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOld = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: sevenDaysOld)
        
        #expect(store.receivedMessages == [.retrieve, .deleteCachedFeed])
    }
    
    @Test("Validate cache deletes cache feed on > 7 days old cache")
    func validateCache_deletesCacheFeed_onMoreThanSevenDaysOldCache( ) {
        let feed = getUniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: moreThanSevenDaysOld)
        
        #expect(store.receivedMessages == [.retrieve, .deleteCachedFeed])
    }
}

// MARK: - Helpers
extension ValidateFeedCacheUseCaseTests {
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

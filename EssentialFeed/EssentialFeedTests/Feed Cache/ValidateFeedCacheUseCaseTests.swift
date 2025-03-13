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
}

// MARK: - Helpers
extension ValidateFeedCacheUseCaseTests {
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

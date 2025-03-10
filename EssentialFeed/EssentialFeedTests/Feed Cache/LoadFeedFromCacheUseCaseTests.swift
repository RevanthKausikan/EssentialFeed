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
        let capturedError = await withCheckedContinuation { continuation in
            sut.load { error in
                continuation.resume(returning: error)
            }
            store.completeRetrieval(with: retrievalError)
        }
        
        #expect(capturedError as? NSError == retrievalError)
    }
}

// MARK: - Helpers
extension LoadFeedFromCacheUseCaseTests {
    private var anyError: NSError { NSError(domain: "any error", code: 1) }
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

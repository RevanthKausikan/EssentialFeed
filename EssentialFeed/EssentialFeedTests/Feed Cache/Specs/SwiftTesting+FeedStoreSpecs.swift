//
//  SwiftTesting+FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import EssentialFeed
import Testing

extension FeedStoreSpecs where Self: EFTesting {
    func assertThatRetrieveDeliversEmptyCacheOnEmptyStore(on sut: FeedStore,
                                                          fileID: String = #fileID, filePath: String = #filePath,
                                                          line: Int = #line, column: Int = #column) async {
        await expect(sut, toRetrieve: .empty, fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func assertThatRetrieveHasNoSideEffectOnEmptyCache(on sut: FeedStore,
                                                       fileID: String = #fileID, filePath: String = #filePath,
                                                       line: Int = #line, column: Int = #column) async {
        await expect(sut, toRetrieveTwice: .empty, fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore,
                                                              fileID: String = #fileID, filePath: String = #filePath,
                                                              line: Int = #line, column: Int = #column) async {
        let feed = getUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp),
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore,
                                                           fileID: String = #fileID, filePath: String = #filePath,
                                                           line: Int = #line, column: Int = #column) async {
        let feed = getUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp),
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore,
                                                     fileID: String = #fileID, filePath: String = #filePath,
                                                     line: Int = #line, column: Int = #column) async {
        let insertionError = await insert(([], Date()), to: sut)
        #expect(insertionError == nil,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
    
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore,
                                                        fileID: String = #fileID, filePath: String = #filePath,
                                                        line: Int = #line, column: Int = #column) async {
        let feed = getUniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = await insert((feed, timestamp), to: sut)
        
        #expect(insertionError == nil,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore,
                                                                fileID: String = #fileID, filePath: String = #filePath,
                                                                line: Int = #line, column: Int = #column) async {
        let firstInsertionError = await insert((getUniqueImageFeed().local, Date()), to: sut)
        #expect(firstInsertionError == nil,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        
        let latestFeed = getUniqueImageFeed().local
        let latestTimestamp = Date()
        
        let latestInsertionError = await insert((latestFeed, latestTimestamp), to: sut)
        #expect(latestInsertionError == nil,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        
        await expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp),
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore,
                                                     fileID: String = #fileID, filePath: String = #filePath,
                                                     line: Int = #line, column: Int = #column) async {
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError == nil,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore,
                                                      fileID: String = #fileID, filePath: String = #filePath,
                                                      line: Int = #line, column: Int = #column) async {
        await deleteCache(from: sut)
        
        await expect(sut, toRetrieve: .empty,
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore,
                                                        fileID: String = #fileID, filePath: String = #filePath,
                                                        line: Int = #line, column: Int = #column) async {
        let feed = getUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError == nil,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore,
                                                        fileID: String = #fileID, filePath: String = #filePath,
                                                        line: Int = #line, column: Int = #column) async {
        let feed = getUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await deleteCache(from: sut)
        
        await expect(sut, toRetrieve: .empty,
                     fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func assertThatSideEffectsRunSerially(on sut: FeedStore, fileID: String = #fileID, filePath: String = #filePath,
                                          line: Int = #line, column: Int = #column) async {
        let op1 = UUID()
        async let insert1 = withCheckedContinuation { continuation in
            sut.insert(getUniqueImageFeed().local, timestamp: Date()) { _ in
                continuation.resume(returning: op1)
            }
        }
        
        let op2 = UUID()
        async let delete = withCheckedContinuation { continuation in
            sut.deleteCachedFeed { _ in
                continuation.resume(returning: op2)
            }
        }
        
        let op3 = UUID()
        async let insert2 = withCheckedContinuation { continuation in
            sut.insert(getUniqueImageFeed().local, timestamp: Date()) { _ in
                continuation.resume(returning: op3)
            }
        }
        
        let completedOperationsInOrder = await [insert1, delete, insert2]
        
        #expect(completedOperationsInOrder == [op1, op2, op3],
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
}

extension FeedStoreSpecs {
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) async -> Error? {
        await withCheckedContinuation { continuation in
            sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
                continuation.resume(returning: insertionError)
            }
        }
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) async -> Error? {
        await withCheckedContinuation { continuation in
            sut.deleteCachedFeed { deletionError in
                continuation.resume(returning: deletionError)
            }
        }
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult,
                        fileID: String = #fileID, filePath: String = #filePath,
                        line: Int = #line, column: Int = #column) async {
        await expect(sut, toRetrieve: expectedResult, fileID: fileID, filePath: filePath, line: line, column: column)
        await expect(sut, toRetrieve: expectedResult, fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCacheFeedResult,
                        fileID: String = #fileID, filePath: String = #filePath,
                        line: Int = #line, column: Int = #column) async {
        await withCheckedContinuation { continuation in
            sut.retrieve { receivedResult in
                switch (receivedResult, expectedResult) {
                case (.empty, .empty), (.failure, .failure): break
                case let (.found(retrievedFeed, retrievedTimestamp), .found(expectedFeed, expectedTimestamp)):
                    #expect(retrievedFeed == expectedFeed, "Expected \(expectedFeed), got \(retrievedFeed)",
                            sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                    #expect(retrievedTimestamp == expectedTimestamp, "Expected \(expectedTimestamp), got \(retrievedTimestamp)",
                            sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                default: Issue.record("Expected \(expectedResult), got \(receivedResult)",
                                      sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                }
                continuation.resume()
            }
        }
    }
}

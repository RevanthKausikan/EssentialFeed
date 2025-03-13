//
//  SwiftTesting+FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import EssentialFeed
import Testing

extension FeedStoreSpecs where Self: EFTesting {
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) async -> Error? {
        await withCheckedContinuation { continuation in
            sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
                continuation.resume(returning: insertionError)
            }
        }
    }
    
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

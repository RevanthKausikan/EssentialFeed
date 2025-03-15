//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Revanth Kausikan on 15/03/25.
//

import Testing
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: EFTesting {
    
    @Test("Load delivers no items on empty cache")
    func load_deliversNoItemsOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        await withCheckedContinuation { continuation in
            sut.load { result in
                switch result {
                case .success(let imageFeed): #expect(imageFeed.isEmpty)
                default: Issue.record("Expected empty result, got \(result)")
                }
                continuation.resume()
            }
        }
    }
    
    @Test("Load delivers items saved on separate instance")
    func load_deliversItemsSavedOnSeparateInstance() async throws {
        let sutToPerformSave = try makeSUT()
        let sutToPerformLoad = try makeSUT()
        let feed = getUniqueImageFeed().models
        
        await withCheckedContinuation { continuation in
            sutToPerformSave.save(feed) { saveError in
                #expect(saveError == nil)
                continuation.resume()
            }
        }
        
        await withCheckedContinuation { continuation in
            sutToPerformLoad.load { result in
                switch result {
                case .success(let imageFeed): #expect(imageFeed == feed)
                default: Issue.record("Expected \(feed), got \(result)")
                }
                continuation.resume()
            }
        }
    }
}

// MARK: - Helpers
extension EssentialFeedCacheIntegrationTests {
    private var testSpecificStoreURL: URL {
        cachesDirectory.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) throws -> LocalFeedLoader {
        let bundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL
        let store = try CoreDataFeedStore(storeURL: storeURL, bundle: bundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        trackForMemoryLeak(store, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
    }
}

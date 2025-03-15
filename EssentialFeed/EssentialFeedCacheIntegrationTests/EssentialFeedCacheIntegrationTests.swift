//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Revanth Kausikan on 15/03/25.
//

import Testing
import EssentialFeed

@Suite(.serialized)
final class EssentialFeedCacheIntegrationTests: EFTesting {
    
    override init() {
        super.init()
        setupEmptyStoreState()
    }
    
    deinit {
        undoStoreSideEffects()
    }
    
    @Test("Load delivers no items on empty cache")
    func load_deliversNoItemsOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        await expect(sut, toLoad: [])
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
        
        await expect(sutToPerformLoad, toLoad: feed)
    }
    
    @Test("Save overrides items saved on separate instance")
    func save_overridesItemsSavedOnSeparateInstance() async throws {
        let sutToPerformFirstSave = try makeSUT()
        let sutToPerformSecondSave = try makeSUT()
        let sutToPerformLoad = try makeSUT()
        let firstFeed = getUniqueImageFeed().models
        let latestFeed = getUniqueImageFeed().models
        
        await withCheckedContinuation { continuation in
            sutToPerformFirstSave.save(firstFeed) { saveError in
                #expect(saveError == nil)
                continuation.resume()
            }
        }
        
        await withCheckedContinuation { continuation in
            sutToPerformSecondSave.save(latestFeed) { saveError in
                #expect(saveError == nil)
                continuation.resume()
            }
        }
        
        await expect(sutToPerformLoad, toLoad: latestFeed)
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
    
    private func expect(_ sut: LocalFeedLoader, toLoad feed: [FeedImage],
                        fileID: String = #fileID, filePath: String = #filePath,
                        line: Int = #line, column: Int = #column) async {
        await withCheckedContinuation { continuation in
            sut.load { result in
                switch result {
                case .success(let imageFeed):
                    #expect(imageFeed == feed,
                            sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                default:
                    Issue.record("Expected \(feed), got \(result)",
                                 sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                }
                continuation.resume()
            }
        }
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
}

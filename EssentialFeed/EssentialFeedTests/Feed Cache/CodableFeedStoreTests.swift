//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import Testing
import EssentialFeed

final class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            .init(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletions) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        do {
            let decoder = JSONDecoder()
            let cached = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cached.localFeed, timestamp: cached.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletions) {
        do {
            let encoder = JSONEncoder()
            let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func deleteCachedFeed(completion: @escaping FeedStore.DeletionCompletions) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

@Suite(.serialized)
final class CodableFeedStoreTests: EFTesting {
    
    override init() {
        super.init()
        setupEmptyStoreState()
    }
    
    deinit {
        undoStoreSideEffects()
    }
    
    @Test("Retrieve delivers empty cache on empty store")
    func retrieve_deliversEmptyCacheOnEmptyStore() async {
        let sut = makeSUT()
        
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Retrieve has no side effect on empty cache")
    func retrieve_hasNoSideEffectOnEmptyCache() async {
        let sut = makeSUT()
        
        await expect(sut, toRetrieveTwice: .empty)
    }
    
   @Test("Retrieve delivers found values on non empty cache")
    func retrieve_deliversFoundValuesOnNonEmptyCache() async {
        let sut = makeSUT()
        let feed = getUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    @Test("Retrieve has no side effects on non empty cache")
     func retrieve_hasNoSideEffectsOnNonEmptyCache() async {
         let sut = makeSUT()
         let feed = getUniqueImageFeed().local
         let timestamp = Date()
         
         await insert((feed, timestamp), to: sut)
         
         await expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
     }
    
    @Test("Retrieve delivers failure on retrieval error")
    func retrieve_deliversFailureOnRetrievalError() async {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieve: .failure(anyError))
    }
    
    @Test("Retrieve has no side effects on retrieval error")
    func retrieve_hasNoSideEffectsOnRetrievalError() async {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieveTwice: .failure(anyError))
    }
    
    @Test("Insert overrides previously inserted cache values")
    func insert_overridesPreviouslyInsertedCacheValues() async throws {
        let sut = makeSUT()
        
        var insertionError = await insert((getUniqueImageFeed().local, Date()), to: sut)
        try #require(insertionError == nil, "Expected no insertion error, got \(String(describing: insertionError))")
        
        let latestFeed = getUniqueImageFeed().local
        let latestTimestamp = Date()
        insertionError = await insert((latestFeed, latestTimestamp), to: sut)
        try #require(insertionError == nil, "Expected no insertion error, got \(String(describing: insertionError))")
        
        await expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    @Test("Insert delivers error on insertion error")
    func insert_deliversErrorOnInsertionError() async {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        let insertionError = await insert((getUniqueImageFeed().local, Date()), to: sut)
        
        #expect(insertionError != nil, "Expected insertion error, got nil")
    }
    
    @Test("Delete has no side effects on empty cache")
    func delete_hasNoSideEffectsOnEmptyCache() async {
        let sut = makeSUT()
        
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError == nil, "Expected no deletion error, got \(String(describing: deletionError))")
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Delete empties previously inserted cache")
    func delete_emptiesPreviouslyInsertedCache() async {
        let sut = makeSUT()
        
        await insert((getUniqueImageFeed().local, Date()), to: sut)
        
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError == nil, "Expected no deletion error, got \(String(describing: deletionError))")
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Delete delivers error on deletion error")
    func delete_deliversErrorOnDeletionError() async {
        let noDeletionPermissionURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletionPermissionURL)
        
        let deletionError = await deleteCache(from: sut)
        
        #expect(deletionError != nil, "Expected deletion error, got nil")
    }
}

// MARK: - Helpers
extension CodableFeedStoreTests {
    private var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func makeSUT(storeURL: URL? = nil, fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) async -> Error? {
        await withCheckedContinuation { continuation in
            sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
                continuation.resume(returning: insertionError)
            }
        }
    }
    
    private func deleteCache(from sut: CodableFeedStore) async -> Error? {
        await withCheckedContinuation { continuation in
            sut.deleteCachedFeed { deletionError in
                continuation.resume(returning: deletionError)
            }
        }
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult,
                        fileID: String = #fileID, filePath: String = #filePath,
                        line: Int = #line, column: Int = #column) async {
        await expect(sut, toRetrieve: expectedResult, fileID: fileID, filePath: filePath, line: line, column: column)
        await expect(sut, toRetrieve: expectedResult, fileID: fileID, filePath: filePath, line: line, column: column)
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCacheFeedResult,
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

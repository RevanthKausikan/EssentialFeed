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
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
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
        let sut = makeSUT()
        
        try! "invalid data".write(to: testSpecificStoreURL, atomically: false, encoding: .utf8)
        
        await expect(sut, toRetrieve: .failure(anyError))
    }
}

// MARK: - Helpers
extension CodableFeedStoreTests {
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL)
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
    }
    
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) async {
        await withCheckedContinuation { continuation in
            sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
                switch insertionError {
                case .none: break
                default: Issue.record("Expected successful insertion, got \(String(describing: insertionError))")
                }
                continuation.resume()
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
    
    private var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}

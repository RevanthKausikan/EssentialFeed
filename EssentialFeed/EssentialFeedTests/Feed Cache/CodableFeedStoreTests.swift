//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import Testing
import EssentialFeed

@Suite(.serialized)
final class CodableFeedStoreTests: EFTesting, FailableFeedStoreSpecs {
    
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
        
        await assertThatRetrieveDeliversEmptyCacheOnEmptyStore(on: sut)
    }
    
    @Test("Retrieve has no side effect on empty cache")
    func retrieve_hasNoSideEffectOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
   @Test("Retrieve delivers found values on non empty cache")
    func retrieve_deliversFoundValuesOnNonEmptyCache() async {
        let sut = makeSUT()
        let feed = getUniqueImageFeed().local
        let timestamp = Date()
        
        await insert((feed, timestamp), to: sut)
        
        await assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    @Test("Retrieve has no side effects on non empty cache")
     func retrieve_hasNoSideEffectsOnNonEmptyCache() async {
         let sut = makeSUT()
         
         await assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
     }
    
    @Test("Retrieve delivers failure on retrieval error")
    func retrieve_deliversFailureOnRetrievalError() async throws {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }
    
    @Test("Retrieve has no side effects on Failure")
    func retrieve_hasNoSideEffectsOnFailure() async throws {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        await assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }
    
    @Test("Insert delivers no error on empty cache")
    func insert_deliversNoErrorOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    @Test("Insert delivers no error on non empty cache")
    func insert_deliversNoErrorOnNonEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    @Test("Insert overrides previously inserted cache values")
    func insert_overridesPreviouslyInsertedCacheValues() async {
        let sut = makeSUT()
        
        await assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    @Test("Insert delivers error on insertion error")
    func insert_deliversErrorOnInsertionError() async {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        await assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    @Test("Insert has no side effects on insertion error")
    func insert_hasNoSideEffectsOnInsertionError() async {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        await assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }
    
    @Test("Delete delivers no error on empty cache")
    func delete_deliversNoErrorOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    @Test("Delete has no side effects on empty cache")
    func delete_hasNoSideEffectsOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }

    @Test("Delete delivers no error on non empty cache")
    func delete_deliversNoErrorOnNonEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    @Test("Delete empties previously inserted cache")
    func delete_emptiesPreviouslyInsertedCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    @Test("Delete delivers error on deletion error")
    func delete_deliversErrorOnDeletionError() async {
        let noDeletionPermissionURL = noDeletePermissionURL
        let sut = makeSUT(storeURL: noDeletionPermissionURL)
        
        await assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }
    
    @Test("Delete has no side effects on deletion error")
    func delete_hasNoSideEffectsOnDeletionError() async {
        let noDeletionPermissionURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletionPermissionURL)
        
        await assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
    }
    
    @Test("Store side effects run serially")
    func storeSideEffectsRunSerially() async {
        let sut = makeSUT()
        
        await assertThatSideEffectsRunSerially(on: sut)
    }
}

// MARK: - Helpers
extension CodableFeedStoreTests {
    private var testSpecificStoreURL: URL {
        cachesDirectory.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private var noDeletePermissionURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }
    
    private func makeSUT(storeURL: URL? = nil, fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
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

//
//  CoreDataFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 14/03/25.
//

import Testing
import EssentialFeed

@Suite(.serialized)
final class CoreDataFeedStoreTests: EFTesting, FeedStoreSpecs {
    @Test("Retrieve - Deliver empty cache on empty store")
    func retrieve_deliversEmptyCacheOnEmptyStore() async {
        let sut = makeSUT()
        
        await assertThatRetrieveDeliversEmptyCacheOnEmptyStore(on: sut)
    }
    
    @Test("Retrieve - Has no side effect on empty cache")
    func retrieve_hasNoSideEffectOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    @Test("Retrieve - Deliver found values on non-empty cache")
    func retrieve_deliversFoundValuesOnNonEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    @Test("Retrieve - Has no side effects on non-empty cache")
    func retrieve_hasNoSideEffectsOnNonEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    @Test("Insert - Deliver no error on empty cache")
    func insert_deliversNoErrorOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    @Test("Insert - Delivers no error on non-empty cache")
    func insert_deliversNoErrorOnNonEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    @Test("Insert - Overrides previously inserted cache values")
    func insert_overridesPreviouslyInsertedCacheValues() async {
        let sut = makeSUT()
        
        await assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    @Test("Delete - Deliver no error on empty cache")
    func delete_deliversNoErrorOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    @Test("Delete - Has no side effects on empty cache")
    func delete_hasNoSideEffectsOnEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    @Test("Delete - Deliver no error on non-empty cache")
    func delete_deliversNoErrorOnNonEmptyCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    @Test("Delete - Empties previously inserted cache")
    func delete_emptiesPreviouslyInsertedCache() async {
        let sut = makeSUT()
        
        await assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func storeSideEffectsRunSerially() async {
        
    }
}

// MARK: - Helpers
extension CoreDataFeedStoreTests {
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> CoreDataFeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
    }
}

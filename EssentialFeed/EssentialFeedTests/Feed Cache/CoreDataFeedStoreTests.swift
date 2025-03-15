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
    func retrieve_deliversEmptyCacheOnEmptyStore() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveDeliversEmptyCacheOnEmptyStore(on: sut)
    }
    
    @Test("Retrieve - Has no side effect on empty cache")
    func retrieve_hasNoSideEffectOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    @Test("Retrieve - Deliver found values on non-empty cache")
    func retrieve_deliversFoundValuesOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    @Test("Retrieve - Has no side effects on non-empty cache")
    func retrieve_hasNoSideEffectsOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    @Test("Insert - Deliver no error on empty cache")
    func insert_deliversNoErrorOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    @Test("Insert - Delivers no error on non-empty cache")
    func insert_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    @Test("Insert - Overrides previously inserted cache values")
    func insert_overridesPreviouslyInsertedCacheValues() async throws {
        let sut = try makeSUT()
        
        await assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    @Test("Delete - Deliver no error on empty cache")
    func delete_deliversNoErrorOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    @Test("Delete - Has no side effects on empty cache")
    func delete_hasNoSideEffectsOnEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    @Test("Delete - Deliver no error on non-empty cache")
    func delete_deliversNoErrorOnNonEmptyCache() async throws {
        let sut = try makeSUT()
        
        await assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    @Test("Delete - Empties previously inserted cache")
    func delete_emptiesPreviouslyInsertedCache() async throws {
        let sut = try makeSUT()
        
        await assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    @Test("Core data store side effects run serially")
    func storeSideEffectsRunSerially() async throws {
        let sut = try makeSUT()
        
        await assertThatSideEffectsRunSerially(on: sut)
    }
}

// MARK: - Helpers
extension CoreDataFeedStoreTests {
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) throws -> CoreDataFeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
    }
}

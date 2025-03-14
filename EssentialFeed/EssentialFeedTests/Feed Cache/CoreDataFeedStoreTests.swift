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
    
    func retrieve_hasNoSideEffectOnEmptyCache() async {
        
    }
    
    func retrieve_deliversFoundValuesOnNonEmptyCache() async {
        
    }
    
    func retrieve_hasNoSideEffectsOnNonEmptyCache() async {
        
    }
    
    func insert_deliversNoErrorOnEmptyCache() async {
        
    }
    
    func insert_deliversNoErrorOnNonEmptyCache() async {
        
    }
    
    func insert_overridesPreviouslyInsertedCacheValues() async {
        
    }
    
    func delete_deliversNoErrorOnEmptyCache() async {
        
    }
    
    func delete_hasNoSideEffectsOnEmptyCache() async {
        
    }
    
    func delete_deliversNoErrorOnNonEmptyCache() async {
        
    }
    
    func delete_emptiesPreviouslyInsertedCache() async {
        
    }
    
    func storeSideEffectsRunSerially() async {
        
    }
}

// MARK: - Helpers
extension CoreDataFeedStoreTests {
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> CoreDataFeedStore {
        let sut = CoreDataFeedStore()
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
    }
}

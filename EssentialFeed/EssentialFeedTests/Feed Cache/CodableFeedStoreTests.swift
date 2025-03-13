//
//  CodableFeedStoreTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//

import Testing
import EssentialFeed

final class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrievalCompletions) {
        completion(.empty)
    }
}

struct CodableFeedStoreTests {
    @Test("Retrieve delivers empty cache on empty store")
    func retrieve_deliversEmptyCacheOnEmptyStore() async {
        let sut = CodableFeedStore()
        
        await withCheckedContinuation { continuation in
            sut.retrieve { result in
                switch result {
                case .empty: break
                default: Issue.record("Expected empty result, got \(result)")
                }
                continuation.resume()
            }
        }
    }
    
    @Test("Retrieve has no side effect on empty cache")
    func retrieve_hasNoSideEffectOnEmptyCache() async {
        let sut = CodableFeedStore()
        
        await withCheckedContinuation { continuation in
            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                    case (.empty, .empty): break
                    default: Issue.record("Expected empty result, got \(firstResult) and \(secondResult)")
                    }
                    continuation.resume()
                }
            }
        }
    }
}

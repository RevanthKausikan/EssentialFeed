//
//  FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//


protocol FeedStoreSpecs {
    func retrieve_deliversEmptyCacheOnEmptyStore() async throws
    func retrieve_hasNoSideEffectOnEmptyCache() async throws
    func retrieve_deliversFoundValuesOnNonEmptyCache() async throws
    func retrieve_hasNoSideEffectsOnNonEmptyCache() async throws
    
    func insert_deliversNoErrorOnEmptyCache() async throws
    func insert_deliversNoErrorOnNonEmptyCache() async throws
    func insert_overridesPreviouslyInsertedCacheValues() async throws
    
    func delete_deliversNoErrorOnEmptyCache() async throws
    func delete_hasNoSideEffectsOnEmptyCache() async throws
    func delete_deliversNoErrorOnNonEmptyCache() async throws
    func delete_emptiesPreviouslyInsertedCache() async throws
    
    func storeSideEffectsRunSerially() async throws
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func retrieve_deliversFailureOnRetrievalError() async throws
    func retrieve_hasNoSideEffectsOnFailure() async throws
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func insert_deliversErrorOnInsertionError() async throws
    func insert_hasNoSideEffectsOnInsertionError() async throws
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func delete_deliversErrorOnDeletionError() async throws
    func delete_hasNoSideEffectsOnDeletionError() async throws
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs

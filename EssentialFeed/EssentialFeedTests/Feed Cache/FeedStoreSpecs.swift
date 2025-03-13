//
//  FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 13/03/25.
//


protocol FeedStoreSpecs {
    func retrieve_deliversEmptyCacheOnEmptyStore() async
    func retrieve_hasNoSideEffectOnEmptyCache() async
    func retrieve_deliversFoundValuesOnNonEmptyCache() async
    func retrieve_hasNoSideEffectsOnNonEmptyCache() async
    
    func insert_overridesPreviouslyInsertedCacheValues() async throws
    
    func delete_hasNoSideEffectsOnEmptyCache() async
    func delete_emptiesPreviouslyInsertedCache() async
    
    func storeSideEffectsRunSerially() async
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func retrieve_deliversFailureOnRetrievalError() async
    func retrieve_hasNoSideEffectsOnRetrievalError() async
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func insert_deliversErrorOnInsertionError() async
    func insert_hasNoSideEffectsOnInsertionError() async
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func delete_deliversErrorOnDeletionError() async
    func delete_hasNoSideEffectsOnDeletionError() async
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
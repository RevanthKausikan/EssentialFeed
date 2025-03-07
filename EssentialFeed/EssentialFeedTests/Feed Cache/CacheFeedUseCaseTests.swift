//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 07/03/25.
//

import Testing

struct FeedStore {
    var deleteCachedFeedCallCount = 0
}

struct LocalFeedLoader {
    let store: FeedStore
}

struct CacheFeedUseCaseTests {

    @Test("Init doesn't delete cache upon creation")
    func init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        
        #expect(store.deleteCachedFeedCallCount == 0)
    }

}

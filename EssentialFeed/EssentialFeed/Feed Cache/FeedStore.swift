//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 07/03/25.
//

public enum RetrieveCacheFeedResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeletionCompletions = (Error?) -> Void
    typealias InsertionCompletions = (Error?) -> Void
    typealias RetrievalCompletions = (RetrieveCacheFeedResult) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletions)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletions)
    func retrieve(completion: @escaping RetrievalCompletions)
}

//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 07/03/25.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletions = (Error?) -> Void
    typealias InsertionCompletions = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletions)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletions)
}

//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 10/03/25.
//

import Foundation 
import EssentialFeed

final class FeedStoreSpy: FeedStore {
    typealias DeletionCompletions = (Error?) -> Void
    typealias InsertionCompletions = (Error?) -> Void
    typealias RetrievalCompletions = (Error?) -> Void
    
    var deletionCompletions = [DeletionCompletions]()
    var insertionCompletions = [InsertionCompletions]()
    var retrievalCompletions = [RetrievalCompletions]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletions) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletions) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func retrieve(completion: @escaping RetrievalCompletions) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](error)
    }
}

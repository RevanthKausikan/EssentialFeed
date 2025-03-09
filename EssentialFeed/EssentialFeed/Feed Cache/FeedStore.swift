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
    func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletions)
}

public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}

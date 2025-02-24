//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 24/02/25.
//

enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    let url: URL
    let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivityError, invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data, let response):
                do {
                    let items = try FeedItemsMapper.map(data, from: response)
                    completion(.success(items.asModels))
                } catch {
                    completion(.failure(error))
                }
            case .failure: completion(.failure(Error.connectivityError))
            }
        }
    }
}

fileprivate extension Array where Element == RemoteFeedItem {
    var asModels: [FeedItem] {
        map { .init(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.image) }
    }
}

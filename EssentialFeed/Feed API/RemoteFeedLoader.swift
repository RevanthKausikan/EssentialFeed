//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 24/02/25.
//

public final class RemoteFeedLoader {
    let url: URL
    let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivityError, invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data, let response):
                completion(FeedItemsMapper.map(data, from: response))
            case .failure: completion(.failure(.connectivityError))
            }
        }
    }
    
    
}

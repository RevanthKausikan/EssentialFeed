//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 24/02/25.
//

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
            guard let self else { return }
            switch result {
            case .success(let data, let response): completion(map(data, from: response))
            case .failure: completion(.failure(Error.connectivityError))
            }
        }
    }
    
    private func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let items = try FeedItemsMapper.map(data, from: response)
            return .success(items.asModels)
        } catch {
            return .failure(error)
        }
    }
}

fileprivate extension Array where Element == RemoteFeedItem {
    var asModels: [FeedImage] {
        map { .init(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}

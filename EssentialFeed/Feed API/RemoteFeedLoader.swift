//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 24/02/25.
//

public struct RemoteFeedLoader {
    let url: URL
    let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivityError, invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { error, response in
            if response != nil {
                completion(.invalidData)
            } else {
                completion(.connectivityError)
            }
        }
    }
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void)
}

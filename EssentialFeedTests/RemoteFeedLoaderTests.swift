//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Testing
@testable import EssentialFeed

struct RemoteFeedLoader {
    func load() {
        HTTPClient.shared.requestedURL = URL(string: "www.any-url.com")
    }
}

final class HTTPClient {
    static let shared = HTTPClient()
    
    private init() { }
    
    var requestedURL: URL?
}


struct RemoteFeedLoaderTests {

    @Test
    func init_doesNotRequestDataFromURL() {
        let client = HTTPClient.shared
        let _ = RemoteFeedLoader()
        
        #expect(client.requestedURL == nil)
    }
    
    @Test
    func load_requestsDataFromURL() {
        let client = HTTPClient.shared
        let sut = RemoteFeedLoader()
        
        sut.load()
        
        #expect(client.requestedURL != nil)
    }

}

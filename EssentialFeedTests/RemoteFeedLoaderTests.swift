//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Testing
import EssentialFeed

struct RemoteFeedLoaderTests {
    @Test
    func init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        #expect(client.requestedURL == nil)
    }
    
    @Test
    func load_requestsDataFromURL() {
        let url = URL(string: "www.any-one-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        #expect(client.requestedURL == url)
    }
}

// MARK: - Helpers
extension RemoteFeedLoaderTests {
    private func makeSUT(url: URL = URL(string: "www.any-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url,client: client)
        return (sut, client)
    }
    
    private final class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        
        func get(from url: URL) {
            requestedURL = url
        }
    }
}

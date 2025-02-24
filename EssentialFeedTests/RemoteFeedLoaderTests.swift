//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Testing
@testable import EssentialFeed

struct RemoteFeedLoader {
    let url: URL
    let client: HTTPClient
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

final class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func get(from url: URL) {
        requestedURL = url
    }
}


struct RemoteFeedLoaderTests {

    @Test
    func init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        let url = URL(string: "www.any-url.com")!
        let _ = RemoteFeedLoader(url: url,client: client)
        
        #expect(client.requestedURL == nil)
    }
    
    @Test
    func load_requestsDataFromURL() {
        let client = HTTPClientSpy()
        let url = URL(string: "www.any-url.com")!
        let sut = RemoteFeedLoader(url: url, client: client)
        
        sut.load()
        
        #expect(client.requestedURL == url)
    }

}

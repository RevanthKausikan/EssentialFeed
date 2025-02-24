//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Testing
import EssentialFeed

struct RemoteFeedLoaderTests {
    @Test("init does not request data from URL")
    func init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        #expect(client.requestedURLs.isEmpty)
    }
    
    @Test("load requests data from URL")
    func load_requestsDataFromURL() {
        let url = URL(string: "www.any-one-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        #expect(client.requestedURLs == [url])
    }
    
    @Test("load twice requests data from URL twice")
    func loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "www.any-one-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        #expect(client.requestedURLs == [url, url])
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
        var requestedURLs = [URL]()
        
        func get(from url: URL) {
            requestedURLs.append(url)
        }
    }
}

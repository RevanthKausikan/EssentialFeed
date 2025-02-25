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
        
        sut.load { _ in }
        
        #expect(client.requestedURLs == [url])
    }
    
    @Test("load twice requests data from URL twice")
    func loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "www.any-one-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        #expect(client.requestedURLs == [url, url])
    }
    
    @Test("load returns Error on client error")
    func load_returnsError_onClientError() {
        let (sut, client) = makeSUT()
        
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        #expect(capturedErrors == [.connectivityError])
    }
    
    @Test("load returns Error on response other than 200", arguments: [199, 200, 300, 400, 500])
    func load_returnsError_onResponseOtherThan200(statusCode: Int) {
        let (sut, client) = makeSUT()
        
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        client.complete(withStatusCode: statusCode)
        
        #expect(capturedErrors == [.invalidData])
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
        private var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error, nil)
        }
        
        func complete(withStatusCode statusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: statusCode,
                                           httpVersion: nil,
                                           headerFields: nil)
            messages[index].completion(nil, response)
        }
    }
}

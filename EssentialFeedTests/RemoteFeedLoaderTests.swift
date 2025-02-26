//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Testing
import EssentialFeed

final class RemoteFeedLoaderTests: EFTesting {
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
    func load_returnsError_onClientError() async {
        let (sut, client) = makeSUT()
        
        await expect(sut, toCompleteWithResult: .failure(.connectivityError), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    @Test("load returns Error on response other than 200", arguments: [199, 201, 300, 400, 500])
    func load_returnsError_onResponseOtherThan200(statusCode: Int) async {
        let (sut, client) = makeSUT()
        
        await expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
            let emptyItemsData = makeItemsJSON(using: [])
            client.complete(withStatusCode: statusCode, data: emptyItemsData)
        })
    }
    
    @Test("load returns Error on Invalid JSON")
    func load_returnsError_onResponse200_andInvalidJSON() async {
        let (sut, client) = makeSUT()
        
        await expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid_json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    @Test("load returns empty list on empty JSON")
    func load_returnsEmptyList_onEmptyJSON() async {
        let (sut, client) = makeSUT()
        
        await expect(sut, toCompleteWithResult: .success([]), when: {
            let emptyJSON = makeItemsJSON(using: [])
            client.complete(withStatusCode: 200, data: emptyJSON)
        })
    }
    
    @Test("load returns actual list based on given JSON")
    func load_returnsList_basedOnJSON() async {
        let (sut, client) = makeSUT()
        
        let (item1, item1JSON) = getFeedItem(id: UUID(),
                                             imageURL: URL(string: "some-url.com")!)
        
        let (item2, item2JSON) = getFeedItem(id: UUID(),
                                             description: "some description",
                                             location: "some location",
                                             imageURL: URL(string: "some-other-url.com")!)
        
        await expect(sut, toCompleteWithResult: .success([item1, item2]), when: {
            let itemsData = makeItemsJSON(using: [item1JSON, item2JSON])
            client.complete(withStatusCode: 200, data: itemsData)
        })
    }
    
    @Test("Deallocating SUT will not produce result")
    func deallocatingSUT_doesNotCallCompletion() {
        let url = URL(string: "any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON(using: []))
        
        #expect(capturedResults.isEmpty)
    }
}

// MARK: - Helpers
extension RemoteFeedLoaderTests {
    private func makeSUT(url: URL = URL(string: "www.any-url.com")!,
                         fileID: String = #fileID,
                         filePath: String = #filePath,
                         line: Int = #line,
                         column: Int = #column) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url,client: client)
        
        trackForMemoryLeak(client, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithResult expectedResult: RemoteFeedLoader.Result,
                        when action: () -> Void,
                        fileID: String = #fileID,
                        filePath: String = #filePath,
                        line: Int = #line,
                        column: Int = #column) async {
        let sourceLocation = SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
        
        await withCheckedContinuation { continuation in
            sut.load { receivedResult in
                switch (receivedResult, expectedResult) {
                case let (.success(receivedItems), .success(expectedItems)):
                    #expect(receivedItems == expectedItems, sourceLocation: sourceLocation)
                case let (.failure(receivedError), .failure(expectedError)):
                    #expect(receivedError == expectedError, sourceLocation: sourceLocation)
                default:
                    Issue.record("Expected \(expectedResult) but received \(receivedResult) instead.", sourceLocation: sourceLocation)
                }
                continuation.resume()
            }
            
            action()
        }
    }
    
    private func getFeedItem(id: UUID, description: String? = nil,
                             location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let itemJSON = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "url": imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (item, itemJSON)
    }
    
    private func makeItemsJSON(using items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private final class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode statusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: statusCode,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}

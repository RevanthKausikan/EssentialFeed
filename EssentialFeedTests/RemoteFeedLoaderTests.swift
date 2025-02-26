//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Testing
import EssentialFeed

class EFTesting {
    var instances = [Any]()
    
    func trackForMemoryLeak(_ instance: Any) {
        instances.append(instance)
    }
    
    deinit {
        for instance in instances {
            #expect(instance == nil, "Instance should have been deallocated. Potential memory leak.")
        }
    }
}

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
    func load_returnsError_onClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(.connectivityError), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    @Test("load returns Error on response other than 200", arguments: [199, 201, 300, 400, 500])
    func load_returnsError_onResponseOtherThan200(statusCode: Int) {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
            let emptyItemsData = makeItemsJSON(using: [])
            client.complete(withStatusCode: statusCode, data: emptyItemsData)
        })
    }
    
    @Test("load returns Error on Invalid JSON")
    func load_returnsError_onResponse200_andInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid_json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    @Test("load returns empty list on empty JSON")
    func load_returnsEmptyList_onEmptyJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([]), when: {
            let emptyJSON = makeItemsJSON(using: [])
            client.complete(withStatusCode: 200, data: emptyJSON)
        })
    }
    
    @Test("load returns actual list based on given JSON")
    func load_returnsList_basedOnJSON() {
        let (sut, client) = makeSUT()
        
        let (item1, item1JSON) = getFeedItem(id: UUID(),
                                             imageURL: URL(string: "some-url.com")!)
        
        let (item2, item2JSON) = getFeedItem(id: UUID(),
                                             description: "some description",
                                             location: "some location",
                                             imageURL: URL(string: "some-other-url.com")!)
        
        expect(sut, toCompleteWithResult: .success([item1, item2]), when: {
            let itemsData = makeItemsJSON(using: [item1JSON, item2JSON])
            client.complete(withStatusCode: 200, data: itemsData)
        })
    }
}

// MARK: - Helpers
extension RemoteFeedLoaderTests {
    private func makeSUT(url: URL = URL(string: "www.any-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url,client: client)
        
        trackForMemoryLeak(client)
        trackForMemoryLeak(sut)
        
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithResult result: RemoteFeedLoader.Result,
                        when action: () -> Void,
                        fileID: String = #fileID,
                        filePath: String = #filePath,
                        line: Int = #line,
                        column: Int = #column) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        #expect(capturedResults == [result],
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
    
//    private func trackForMemoryLeaks(_ instance: AnyObject) {
    //            addTeardownBlock { [weak instance] in
//                #expect(instance == nil, "Instance should have been deallocated. Potential memory leak.")
//            }
//        }
//    }
    
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

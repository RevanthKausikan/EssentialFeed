//
//  URLSessionHTTPClientTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 26/02/25.
//

import Testing
import Foundation
import EssentialFeed

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        let urlRequest = URLRequest(url: url)
        session.dataTask(with: urlRequest) { _, _, _ in }
    }
}

struct URLSessionHTTPClientTests {
    @Test("Get requests from URL - captures data task with URL")
    func test_getFromURL_createsDataTaskWithURL() {
        let url = URL(string: "any-url.com")!
        let session = URLSessionSpy()
        
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        
        #expect(session.receivedURLs == [url])
    }
}

// MARK: - Helpers
fileprivate final class URLSessionSpy: URLSession, @unchecked Sendable {
    var receivedURLs = [URL]()
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
        receivedURLs.append(request.url!)
        return FakeURLSessionDataTask()
    }
}

fileprivate final class FakeURLSessionDataTask: URLSessionDataTask, @unchecked Sendable { }

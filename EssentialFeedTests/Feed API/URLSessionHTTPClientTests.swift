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
        session.dataTask(with: urlRequest, completionHandler: { _, _, _ in }).resume()
    }
}

struct URLSessionHTTPClientTests {
    @Test("Get requests from URL - Create - captures data task with URL")
    func getFromURL_createsDataTaskWithURL() {
        let url = URL(string: "any-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url)
        
        #expect(session.receivedURLs == [url])
    }
    
    @Test("Get requests from URL - Resume - captures data task with URL")
    func getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "any-url.com")!
        let task = URLSessionDataTaskSpy()
        let session = URLSessionSpy()
        session.stub(url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url)
        
        #expect(task.resumeCallCount == 1)
    }
    
    @Test("Get from URL - fails with request error")
    func getFromURL_failsWithRequestError() {
        let url = URL(string: "any-url.com")!
        let error = NSError(domain: "any error", code: 1)
        let session = URLSessionSpy()
        session.stub(url, error: error)
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url)
    }
}

// MARK: - Helpers
fileprivate final class URLSessionSpy: URLSession, @unchecked Sendable {
    var receivedURLs = [URL]()
    private var stubs = [URL: Stub]()
    
    private struct Stub {
        let task: URLSessionDataTask
        let error: Error?
    }
    
    func stub(_ url: URL, task: URLSessionDataTask = URLSessionDataTaskSpy(), error: Error? = nil) {
        stubs[url] = Stub(task: task, error: error)
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
        if let url = request.url {
            receivedURLs.append(url)
            if let stub = stubs[url] {
                completionHandler(nil, nil, stub.error)
                return stub.task
            }
        }
        return FakeURLSessionDataTask()
    }
}

fileprivate final class FakeURLSessionDataTask: URLSessionDataTask, @unchecked Sendable {
    override func resume() { }
}

fileprivate final class URLSessionDataTaskSpy: URLSessionDataTask, @unchecked Sendable {
    var resumeCallCount = 0
    
    override func resume() {
        resumeCallCount += 1
    }
}

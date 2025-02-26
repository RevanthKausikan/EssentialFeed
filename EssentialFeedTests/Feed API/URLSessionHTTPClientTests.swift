//
//  URLSessionHTTPClientTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 26/02/25.
//

import Testing
import Foundation
import EssentialFeed

protocol HTTPSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

final class URLSessionHTTPClient {
    private let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        let urlRequest = URLRequest(url: url)
        session.dataTask(with: urlRequest) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct URLSessionHTTPClientTests {
    @Test("Get requests from URL - Resume - captures data task with URL")
    func getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "any-url.com")!
        let task = URLSessionDataTaskSpy()
        let session = URLSessionSpy()
        session.stub(url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url) { _ in }
        
        #expect(task.resumeCallCount == 1)
    }
    
    @Test("Get from URL - fails with request error")
    func getFromURL_failsWithRequestError() async {
        let url = URL(string: "any-url.com")!
        let error = NSError(domain: "any error", code: 1)
        let session = URLSessionSpy()
        session.stub(url, error: error)
        let sut = URLSessionHTTPClient(session: session)
        
        await withCheckedContinuation { continuation in
            sut.get(from: url) { result in
                switch result {
                case .failure(let receivedError as NSError):
                    #expect(receivedError == error)
                default: Issue.record("expected to fail with \(error).")
                }
                continuation.resume()
            }
        }
    }
}

// MARK: - Helpers
fileprivate final class URLSessionSpy: HTTPSession {
    private var stubs = [URL: Stub]()
    
    private struct Stub {
        let task: HTTPSessionTask
        let error: Error?
    }
    
    func stub(_ url: URL, task: HTTPSessionTask = URLSessionDataTaskSpy(), error: Error? = nil) {
        stubs[url] = Stub(task: task, error: error)
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> HTTPSessionTask {
        guard let url = request.url, let stub = stubs[url] else {
            fatalError("Couldn't find stub for \(request.url!).")
        }
        completionHandler(nil, nil, stub.error)
        return stub.task
    }
}

fileprivate final class FakeURLSessionDataTask: HTTPSessionTask {
    func resume() { }
}

fileprivate final class URLSessionDataTaskSpy: HTTPSessionTask {
    var resumeCallCount = 0
    
    func resume() {
        resumeCallCount += 1
    }
}

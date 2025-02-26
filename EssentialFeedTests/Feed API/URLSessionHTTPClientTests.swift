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
    
    init(session: URLSession = .shared) {
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
    @Test("Get from URL - fails with request error", .disabled())
    func getFromURL_failsWithRequestError() async {
        URLProtocolStub.startInterceptingRequests()
        
        let url = URL(string: "any-url.com")!
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(url, error: error)
        let sut = URLSessionHTTPClient()
        
        await withCheckedContinuation { continuation in
            sut.get(from: url) { result in
                switch result {
                case .failure(let receivedError as NSError):
                    #expect(receivedError == error)
                default:
                    Issue.record("expected to fail with \(error).")
                }
                continuation.resume()
            }
        }
        
        URLProtocolStub.stopInterceptingRequests()
    }
}

// MARK: - Helpers
fileprivate final class URLProtocolStub: URLProtocol {
    private static var stubs = [URL: Stub]()
    
    private struct Stub {
        let error: Error?
    }
    
    static func stub(_ url: URL, error: Error? = nil) {
        stubs[url] = Stub(error: error)
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stubs = [:]
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        
        return URLProtocolStub.stubs[url] != nil
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

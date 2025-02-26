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
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}

@Suite(.serialized)
struct URLSessionHTTPClientTests {
    @Test("Get from URL - performs GET request with URL")
    func getFromURL_performsGETRequestWithURL() async {
        URLProtocolStub.startInterceptingRequests()
        
        await withCheckedContinuation { continuation in
            let url = URL(string: "any-url.com")!
            URLProtocolStub.observeRequests { request in
                #expect(request.httpMethod == "GET")
                #expect(request.url == url)
            }
            URLSessionHTTPClient().get(from: url) { _ in }
            continuation.resume()
        }
        
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    @Test("Get from URL - fails with request error")
    func getFromURL_failsWithRequestError() async {
        URLProtocolStub.startInterceptingRequests()
        
        let url = URL(string: "any-url.com")!
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        let sut = URLSessionHTTPClient()
        
        await withCheckedContinuation { continuation in
            sut.get(from: url) { result in
                switch result {
                case .failure(let receivedError as NSError):
                    #expect(receivedError.domain == error.domain)
                    #expect(receivedError.code == error.code)
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
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?
    
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        requestObserver = observer
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        requestObserver = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        requestObserver?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

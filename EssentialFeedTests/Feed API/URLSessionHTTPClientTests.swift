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
    
    struct UnexpectedValuesRepresentation: Error { }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

@Suite(.serialized)
final class URLSessionHTTPClientTests: EFTesting {
    
    override init() {
        super.init()
        URLProtocolStub.startInterceptingRequests()
    }
    
    deinit {
        URLProtocolStub.stopInterceptingRequests()
    }
    
    @Test("Get from URL - performs GET request with URL")
    func getFromURL_performsGETRequestWithURL() async {
        await withCheckedContinuation { continuation in
            let url = anyURL
            URLProtocolStub.observeRequests { request in
                #expect(request.httpMethod == "GET")
                #expect(request.url == url)
            }
            makeSUT().get(from: url) { _ in }
            continuation.resume()
        }
    }
    
    @Test("Get from URL - fails with request error")
    func getFromURL_failsWithRequestError() async throws {
        let requestError = NSError(domain: "any error", code: 1)
        let capturedError = await resultErrorFor(data: nil, response: nil, error: requestError)
        
        let receivedError = try #require(capturedError as? NSError)
        #expect(receivedError.domain == requestError.domain)
        #expect(receivedError.code == requestError.code)
    }
    
    @Test("Get from URL - fails for all nil values")
    func getFromURL_failsForAllNilValues() async {
        let receivedError = await resultErrorFor(data: nil, response: nil, error: nil)
        #expect(receivedError != nil)
    }
}

// MARK: - Helpers

extension URLSessionHTTPClientTests {
    private func makeSUT(fileID: String = #fileID,
                         filePath: String = #filePath,
                         line: Int = #line,
                         column: Int = #column) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
    }
    
    private var anyURL: URL {
        URL(string: "any-url.com")!
    }
    
    private func resultErrorFor(data: Data?, response: HTTPURLResponse?, error: Error?,
                                fileID: String = #fileID, filePath: String = #filePath,
                                line: Int = #line, column: Int = #column) async -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(fileID: fileID, filePath: filePath, line: line, column: column)
        
        var capturedError: Error?
        await withCheckedContinuation { continuation in
            sut.get(from: anyURL) { result in
                switch result {
                case .failure(let error): capturedError = error
                default: Issue.record("expected failure, but got \(result).",
                                      sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
                }
                continuation.resume()
            }
        }
        return capturedError
    }
}

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

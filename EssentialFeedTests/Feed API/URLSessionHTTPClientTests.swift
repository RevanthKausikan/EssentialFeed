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
        session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let data, data.count > 0, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
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
        let requestError = anyError
        let capturedError = await resultErrorFor(data: nil, response: nil, error: requestError)
        
        let receivedError = try #require(capturedError as? NSError)
        #expect(receivedError.domain == requestError.domain)
        #expect(receivedError.code == requestError.code)
    }
    
    @Test(
        "Get from URL - fails for invalidConditions",
        arguments: [
            (nil, nil, nil),
            (nil, nonHTTPURLResponse, nil),
            (nil, anyHTTPURLResponse, nil),
            (anyData, nil, nil),
            (anyData, nil, anyError),
            (nil, nonHTTPURLResponse, anyError),
            (nil, anyHTTPURLResponse, anyError),
            (anyData, nonHTTPURLResponse, anyError),
            (anyData, anyHTTPURLResponse, anyError),
            (anyData, nonHTTPURLResponse, nil),
        ]
    )
    func getFromURL_failsForAllInvalidConditions(data: Data?, response: URLResponse?, error: Error?) async {
        #expect(await resultErrorFor(data: data, response: response, error: error) != nil)
    }
    
    @Test("Get from URL - succeeds with HTTPURLResponse and Data")
    func getFromURL_succeedsWithHTTPURLResponseAndData() async {
        let data = anyData
        let response = anyHTTPURLResponse
        URLProtocolStub.stub(data: data, response: response, error: nil)
        
        await withCheckedContinuation { continuation in
            makeSUT().get(from: anyURL) { result in
                switch result {
                case .success(let receivedData, let receivedResponse):
                    #expect(receivedData == data)
                    #expect(receivedResponse.statusCode == response?.statusCode)
                    #expect(receivedResponse.url == response?.url)
                default: Issue.record("expected failure, but got \(result).")
                }
                continuation.resume()
            }
        }
    }
}

// MARK: - Helpers

private var anyURL: URL { URL(string: "any-url.com")! }
private var anyData: Data { Data("any-data".utf8) }
private var anyError: NSError { NSError(domain: "any error", code: 1) }
private var nonHTTPURLResponse: URLResponse { URLResponse(url: anyURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil) }
private var anyHTTPURLResponse: HTTPURLResponse? { HTTPURLResponse(url: anyURL, statusCode: 200, httpVersion: nil, headerFields: nil) }

extension URLSessionHTTPClientTests {
    private func makeSUT(fileID: String = #fileID,
                         filePath: String = #filePath,
                         line: Int = #line,
                         column: Int = #column) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?,
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

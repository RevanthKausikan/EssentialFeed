//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Revanth Kausikan on 04/03/25.
//

import Testing
import EssentialFeed

struct EssentialFeedAPIEndToEndTests {

    @Test("GET call matches expected data")
    func endToEndTestServerGETFeedResult_matchesFixedTestAccountData() async {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: testServerURL, client: client)
        
        
        
        var receivedResult: LoadFeedResult?
        await withCheckedContinuation { continuation in
            loader.load { result in
                receivedResult = result
                continuation.resume()
            }
        }
        
        switch receivedResult {
        case .success(let items): #expect(items.count == 8, "Expected 8 items but got \(items.count) instead")
        case .failure(let error): Issue.record("Expected to get success, but received \(error) instead.")
        default: Issue.record("Expected to get results, but didn't.")
        }
    }

}

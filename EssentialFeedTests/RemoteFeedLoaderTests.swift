//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Testing
@testable import EssentialFeed

struct RemoteFeedLoader {
    
}

struct HTTPClient {
    var requestedURL: URL?
}


struct RemoteFeedLoaderTests {

    @Test func init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        let _ = RemoteFeedLoader()
        
        #expect(client.requestedURL == nil)
    }

}

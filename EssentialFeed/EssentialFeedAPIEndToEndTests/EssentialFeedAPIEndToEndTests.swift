//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Revanth Kausikan on 04/03/25.
//

import Testing
import EssentialFeed

final class EssentialFeedAPIEndToEndTests: EFTesting {
    
    @Test("GET call matches expected data")
    func endToEndTestServerGETFeedResult_matchesFixedTestAccountData() async {
        switch await getFeedResult() {
        case .success(let imageFeed):
            #expect(imageFeed.count == 8, "Expected 8 items but got \(imageFeed.count) instead")
            #expect(imageFeed[0] == expectedImage(at: 0))
            #expect(imageFeed[1] == expectedImage(at: 1))
            #expect(imageFeed[2] == expectedImage(at: 2))
            #expect(imageFeed[3] == expectedImage(at: 3))
            #expect(imageFeed[4] == expectedImage(at: 4))
            #expect(imageFeed[5] == expectedImage(at: 5))
            #expect(imageFeed[6] == expectedImage(at: 6))
            #expect(imageFeed[7] == expectedImage(at: 7))
            
        case .failure(let error): Issue.record("Expected to get success, but received \(error) instead.")
        default: Issue.record("Expected to get results, but didn't.")
        }
    }
}

// MARK: - Helpers
extension EssentialFeedAPIEndToEndTests {
    private func getFeedResult(fileID: String = #fileID,
                               filePath: String = #filePath,
                               line: Int = #line,
                               column: Int = #column) async -> LoadFeedResult {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let loader = RemoteFeedLoader(url: testServerURL, client: client)
        trackForMemoryLeak(client, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        trackForMemoryLeak(loader, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return await withCheckedContinuation { continuation in
            loader.load { continuation.resume(returning: $0) }
        }
    }
    
    private func expectedImage(at index: Int) -> FeedImage {
        FeedImage(
            id: id(at: index),
            description: description(at: index),
            location: location(at: index),
            url: imageURL(at: index))
    }
    
    private func id(at index: Int) -> UUID {
        UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][index])!
    }
    
    private func description(at index: Int) -> String? {
        [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }
    
    private func location(at index: Int) -> String? {
        [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }
    
    private func imageURL(at index: Int) -> URL {
        URL(string: "https://url-\(index+1).com")!
    }
}

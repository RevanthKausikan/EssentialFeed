//
//  FeedUIIntegrationTests+Assertions.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import Testing
import EssentialFeed
import EssentialFeediOS

extension FeedUIIntegrationTests {
    func assertThat(_ sut: FeedViewController, isRendering feed: [FeedImage],
                            fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) throws {
        try #require(sut.numberOfRenderedFeedImageViews == feed.count)
        try feed.enumerated().forEach { (index, image) in
            try assertThat(sut, hasViewConfiguredFor: image, at: index, fileID: fileID, filePath: filePath, line: line, column: column)
        }
    }
    
    func assertThat(_ sut: FeedViewController, hasViewConfiguredFor image: FeedImage, at index: Int,
                            fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) throws {
        let cell = try #require(sut.feedImageView(at: index) as? FeedImageCell)
        #expect(cell.isShowingLocation == (image.location != nil),
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        #expect(cell.locationText == image.location,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        #expect(cell.descriptionText == image.description,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
}

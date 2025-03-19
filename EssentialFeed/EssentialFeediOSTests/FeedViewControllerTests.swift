//
//  FeedViewControllerTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 18/03/25.
//

import Testing
import UIKit
import EssentialFeed
import EssentialFeediOS

@MainActor
final class FeedViewControllerTests: EFTesting {
    @Test("Load feed action - request feed from loader",
          .disabled("iOS 17 migration pending"),
          .bug("https://github.com/essentialdevelopercom/essential-feed-case-study/pull/75/files"))
    func loadFeedAction_requestsFeedFromLoader() {
        let (sut, loader) = makeSUT()
        #expect(loader.loadCallCount == 0)
    
        sut.loadViewIfNeeded()
        #expect(loader.loadCallCount == 1)
        
        sut.simulateUserInitiatedReload()
        #expect(loader.loadCallCount == 2)
        
        sut.simulateUserInitiatedReload()
        #expect(loader.loadCallCount == 3)
    }
    
    @Test("Loading feed indicator - is visible while loading",
          .disabled("iOS 17 migration pending"),
          .bug("https://github.com/essentialdevelopercom/essential-feed-case-study/pull/75/files"))
    func loadingFeedIndicator_isVisibleWhileLoading() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        #expect(sut.isShowingLoadingIndicator)
    
        loader.completeFeedLoading(at: 0)
        #expect(!sut.isShowingLoadingIndicator)
        
        sut.simulateUserInitiatedReload()
        #expect(sut.isShowingLoadingIndicator)
        
        loader.completeFeedLoading(at: 1)
        #expect(!sut.isShowingLoadingIndicator)
    }
    
    @Test("Load feed completion - renders successfully loaded images")
    func loadFeedCompletion_rendersSuccessfullyLoadedImages() throws {
        let image0 = makeImage(description: "a description", location: "a location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        try assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0], at: 0)
        try assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoading(with: [image0, image1, image2, image3], at: 1)
        try assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    @Test("Load feed completion - does not alter current rendering state on error")
    func loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() throws {
        let image0 = makeImage(description: "a description", location: "a location")
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0], at: 0)
        try assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedReload()
        loader.completeFeedLoadingWithError(at: 1)
        try assertThat(sut, isRendering: [image0])
    }
}

// MARK: - Helpers
extension FeedViewControllerTests {
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
//        trackForMemoryLeak(loader, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return (sut, loader)
    }
    
    private func assertThat(_ sut: FeedViewController, isRendering feed: [FeedImage],
                            fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) throws {
        try #require(sut.numberOfRenderedFeedImageViews == feed.count)
        try feed.enumerated().forEach { (index, image) in
            try assertThat(sut, hasViewConfiguredFor: image, at: index, fileID: fileID, filePath: filePath, line: line, column: column)
        }
    }
    
    private func assertThat(_ sut: FeedViewController, hasViewConfiguredFor image: FeedImage, at index: Int,
                            fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) throws {
        let cell = try #require(sut.feedImageView(at: index) as? FeedImageCell)
        #expect(cell.isShowingLocation == (image.location != nil),
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        #expect(cell.locationText == image.location,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        #expect(cell.descriptionText == image.description,
                sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
    }
    
    private func makeImage(description: String? = nil, location: String? = nil,
                           url: URL = URL(string: "any-url.com")!) -> FeedImage {
        .init(id: UUID(), description: description, location: location, url: url)
    }
}

fileprivate extension FeedViewController {
    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
    
    var numberOfRenderedFeedImageViews: Int {
        tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    
    private var feedImagesSection: Int { 0 }
}

fileprivate extension FeedImageCell {
    var isShowingLocation: Bool { !locationContainer.isHidden }
    var locationText: String? { locationLabel.text }
    var descriptionText: String? { descriptionLabel.text }
}

fileprivate extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?
                .forEach { (target as NSObject).perform(Selector($0)) }
        }
    }
}

final class LoaderSpy: FeedLoader {
    private var completions: [(FeedLoader.Result) -> Void] = []
    var loadCallCount: Int { completions.count }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        completions.append(completion)
    }
    
    func completeFeedLoading(with feedImages: [FeedImage] = [], at index: Int) {
        completions[index](.success(feedImages))
    }
    
    func completeFeedLoadingWithError(at index: Int) {
        let error = NSError(domain: "an error", code: 0)
        completions[index](.failure(error))
    }
}

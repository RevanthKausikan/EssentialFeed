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
    
    @Test("Feed view has title")
    func feedView_hasTitle() {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        #expect(sut.title == "My feed")
    }
    
    @Test("Load feed action - request feed from loader",
          .disabled("iOS 17 migration pending"),
          .bug("https://github.com/essentialdevelopercom/essential-feed-case-study/pull/75/files"))
    func loadFeedAction_requestsFeedFromLoader() {
        let (sut, loader) = makeSUT()
        #expect(loader.loadFeedCallCount == 0)
        
        sut.loadViewIfNeeded()
        #expect(loader.loadFeedCallCount == 1)
        
        sut.simulateUserInitiatedReload()
        #expect(loader.loadFeedCallCount == 2)
        
        sut.simulateUserInitiatedReload()
        #expect(loader.loadFeedCallCount == 3)
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
        
        loader.completeFeedLoadingWithError(at: 1)
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
    
    @Test("Feed image view - loads image URL when visible")
    func feedImageView_loadsImageURLWhenVisible() throws {
        let image0 = makeImage(url: URL(string: "https://example.com/image0")!)
        let image1 = makeImage(url: URL(string: "https://example.com/image1")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])
        #expect(loader.loadedImageURLs == [])
        
        
        sut.simulateFeedImageViewVisible(at: 0)
        #expect(loader.loadedImageURLs == [image0.url])
        
        sut.simulateFeedImageViewVisible(at: 1)
        #expect(loader.loadedImageURLs == [image0.url, image1.url])
    }
    
    @Test("Feed image view - cancels image loading when not visible anymore")
    func feedImageView_cancelsImageLoadingWhenNotVisibleAnymore() throws {
        let image0 = makeImage(url: URL(string: "https://example.com/image0")!)
        let image1 = makeImage(url: URL(string: "https://example.com/image1")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])
        #expect(loader.cancelledImageURLs == [])
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        #expect(loader.cancelledImageURLs == [image0.url])
        
        sut.simulateFeedImageViewNotVisible(at: 1)
        #expect(loader.cancelledImageURLs == [image0.url, image1.url])
    }
    
    @Test("Feed image view loading indicator - is visible while loading image")
    func feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() throws {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        #expect(view0?.isShowingImageLoadingIndicator == true)
        #expect(view1?.isShowingImageLoadingIndicator == true)
        
        loader.completeImageLoading(at: 0)
        #expect(view0?.isShowingImageLoadingIndicator == false)
        #expect(view1?.isShowingImageLoadingIndicator == true)
        
        loader.completeImageLoadingWithError(at: 1)
        #expect(view0?.isShowingImageLoadingIndicator == false)
        #expect(view1?.isShowingImageLoadingIndicator == false)
    }
    
    @Test("Feed image view - renders image loaded from URL")
    func feedImageView_rendersImageLoadedFromURL() throws {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        #expect(view0?.renderedImage == .none)
        #expect(view1?.renderedImage == .none)
        
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData0, at: 0)
        #expect(view0?.renderedImage == imageData0)
        #expect(view1?.renderedImage == .none)
        
        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        loader.completeImageLoading(with: imageData1, at: 1)
        #expect(view0?.renderedImage == imageData0)
        #expect(view1?.renderedImage == imageData1)
    }
    
    @Test("Feed image view retry button - is visible on image URL load error")
    func feedImageViewRetryButton_isVisibleOnImageURLLoadError() throws {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        #expect(view0?.isShowingRetryAction == false)
        #expect(view1?.isShowingRetryAction == false)
        
        let imageData = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData, at: 0)
        #expect(view0?.isShowingRetryAction == false)
        #expect(view1?.isShowingRetryAction == false)
        
        loader.completeImageLoadingWithError(at: 1)
        #expect(view0?.isShowingRetryAction == false)
        #expect(view1?.isShowingRetryAction == true)
    }
    
    @Test("Feed image view retry button - is visible on invalid image data")
    func feedImageViewRetryButton_isVisibleOnInvalidImageData() throws {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewVisible(at: 0)
        #expect(view?.isShowingRetryAction == false)
        
        let invalidImageData = Data("invalid image data".utf8)
        loader.completeImageLoading(with: invalidImageData, at: 0)
        #expect(view?.isShowingRetryAction == true)
    }
    
    @Test("Feed image view retry action - retires image load")
    func feedImageViewRetryAction_retriesImageLoad() throws {
        let image0 = makeImage(url: URL(string: "https://example.com/image0")!)
        let image1 = makeImage(url: URL(string: "https://example.com/image1")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        #expect(loader.loadedImageURLs == [image0.url, image1.url])
        
        loader.completeImageLoadingWithError(at: 0)
        loader.completeImageLoadingWithError(at: 1)
        #expect(loader.loadedImageURLs == [image0.url, image1.url])
        
        view0?.simulateRetryAction()
        #expect(loader.loadedImageURLs == [image0.url, image1.url, image0.url])
        
        view1?.simulateRetryAction()
        #expect(loader.loadedImageURLs == [image0.url, image1.url, image0.url, image1.url])
    }
    
    @Test("Feed image view - preloads image URL with near visible")
    func feedImageView_preloadsImageURLWithNearVisible() throws {
        let image0 = makeImage(url: URL(string: "https://example.com/image0")!)
        let image1 = makeImage(url: URL(string: "https://example.com/image1")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])
        #expect(loader.loadedImageURLs == [])
        
        sut.simulateFeedImageNearVisible(at: 0)
        #expect(loader.loadedImageURLs == [image0.url])
        
        sut.simulateFeedImageNearVisible(at: 1)
        #expect(loader.loadedImageURLs == [image0.url, image1.url])
    }
    
    @Test("Feed image view - cancels image URL preloading when not visible anymore")
    func feedImageView_cancelsImageURLPreloadingWhenNotVisibleAnymore() throws {
        let image0 = makeImage(url: URL(string: "https://example.com/image0")!)
        let image1 = makeImage(url: URL(string: "https://example.com/image1")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])
        #expect(loader.cancelledImageURLs == [])
        
        sut.simulateFeedImageViewNotNearVisible(at: 0)
        #expect(loader.cancelledImageURLs == [image0.url])
        
        sut.simulateFeedImageViewNotNearVisible(at: 1)
        #expect(loader.cancelledImageURLs == [image0.url, image1.url])
    }
    
    @Test("Feed image view - does not render lodaded image when not visible anymore")
    func feedImageView_doesNotRenderLodadedImageWhenNotVisibleAnymore() throws {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewNotVisible(at: 0)
        loader.completeImageLoading(with: anyImageData)
        
        #expect(view?.renderedImage == nil)
    }
}

// MARK: - Helpers
extension FeedViewControllerTests {
    private var anyImageData: Data { UIImage.make(withColor: .red).pngData()! }
    
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(feedLoader: loader, imageLoader: loader)
//        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
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
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        feedImageView(at: index) as? FeedImageCell
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    
    @discardableResult
    func simulateFeedImageViewNotVisible(at row: Int) -> FeedImageCell? {
        let view = simulateFeedImageViewVisible(at: row)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
        
        return view
    }
    
    func simulateFeedImageNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageNearVisible(at: row)
        
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
    
    var numberOfRenderedFeedImageViews: Int {
        tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    private var feedImagesSection: Int { 0 }
}

fileprivate extension FeedImageCell {
    var isShowingLocation: Bool { !locationContainer.isHidden }
    var locationText: String? { locationLabel.text }
    var descriptionText: String? { descriptionLabel.text }
    var isShowingImageLoadingIndicator: Bool { feedImageContainer.isShimmering }
    var isShowingRetryAction: Bool { !feedImageRetryButton.isHidden }
    var renderedImage: Data? { feedImageView.image?.pngData() }
    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
}

fileprivate extension UIButton {
    func simulateTap() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .touchUpInside)?
                .forEach { (target as NSObject).perform(Selector($0)) }
        }
    }
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
    private var feedRequests: [(FeedLoader.Result) -> Void] = []
    var loadFeedCallCount: Int { feedRequests.count }
    
    private var imageRequests = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()
    var loadedImageURLs: [URL] { imageRequests.map { $0.url } }
    private(set) var cancelledImageURLs = [URL]()
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        feedRequests.append(completion)
    }
    
    func completeFeedLoading(with feedImages: [FeedImage] = [], at index: Int = 0) {
        feedRequests[index](.success(feedImages))
    }
    
    func completeFeedLoadingWithError(at index: Int) {
        let error = NSError(domain: "an error", code: 0)
        feedRequests[index](.failure(error))
    }
    
    func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
        imageRequests[index].completion(.success(imageData))
    }
    
    func completeImageLoadingWithError(at index: Int = 0) {
        let error = NSError(domain: "an error", code: 0)
        imageRequests[index].completion(.failure(error))
    }
}

extension LoaderSpy: FeedImageDataLoader {
    
    private struct TaskSpy: FeedImageDataLoaderTask {
        let cancelCallback: () -> Void
        func cancel() {
            cancelCallback()
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        imageRequests.append((url, completion))
        return TaskSpy { [weak self] in self?.cancelledImageURLs.append(url) }
    }
}

private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { rendererContext in
            color.setFill()
            rendererContext.fill(rect)
        }
    }
}

//
//  FeedViewControllerTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 18/03/25.
//

import Testing
import UIKit
import EssentialFeed

final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        refreshControl?.beginRefreshing()
        load()
    }
    
    @objc private func load() {
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

@MainActor
final class FeedViewControllerTests: EFTesting {
    @Test("Init does not load feed")
    func init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        #expect(loader.loadCallCount == 0)
    }
    
    @Test("ViewDidLoad loads feed")
    func viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        
        #expect(loader.loadCallCount == 1)
    }
    
    @Test("viewDidLoad shows loading indicator")
    func viewDidLoad_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        #expect(sut.isShowingLoadingIndicator)
    }
    
    @Test("viewDidLoad hides loading indicator on loader completion")
    func viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading()
        
        #expect(sut.isShowingLoadingIndicator)
    }
    
    @Test("User initiated feed refresh - realoads feed")
    func userInitiatedFeedRefresh_reloadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        
        sut.simulatePullToRefresh()
        #expect(loader.loadCallCount == 2)
        
        sut.simulatePullToRefresh()
        #expect(loader.loadCallCount == 3)
    }
    
    @Test("User initiated feed refresh - shows loading indicator")
    func userInitiatedFeedRefresh_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        
        sut.simulatePullToRefresh()
        
        #expect(sut.isShowingLoadingIndicator)
    }
    
    @Test("User initiated feed refresh - hides loading indicator on loader completion")
    func userInitiatedFeedRefresh_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        
        sut.simulatePullToRefresh()
        loader.completeFeedLoading()
        
        #expect(sut.isShowingLoadingIndicator)
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
}

fileprivate extension FeedViewController {
    func simulatePullToRefresh() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
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
    private var completions: [(FeedLoader.Result) -> Void] = []
    var loadCallCount: Int { completions.count }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        completions.append(completion)
    }
    
    func completeFeedLoading() {
        completions[0](.success([]))
    }
}

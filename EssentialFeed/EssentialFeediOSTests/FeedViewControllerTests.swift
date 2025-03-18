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
        load()
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

@MainActor
final class FeedViewControllerTests: EFTesting {
    @Test("Load feed action - request feed from loader")
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
    
    @Test("Loading feed indicator - is visible while loading")
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
}

// MARK: - Helpers
extension FeedViewControllerTests {
    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath,
                         line: Int = #line, column: Int = #column) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeak(sut, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        trackForMemoryLeak(loader, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column))
        return (sut, loader)
    }
}

fileprivate extension FeedViewController {
    func simulateUserInitiatedReload() {
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
    
    func completeFeedLoading(at index: Int) {
        completions[0](.success([]))
    }
}

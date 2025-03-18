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

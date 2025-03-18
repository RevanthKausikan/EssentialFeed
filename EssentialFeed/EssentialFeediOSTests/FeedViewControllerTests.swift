//
//  FeedViewControllerTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 18/03/25.
//

import Testing

final class FeedViewController {
    init(loader: LoaderSpy) {
        
    }
}

final class FeedViewControllerTests: EFTesting {
    @Test("Init does not load feed")
    func init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        #expect(loader.loadCallCount == 0)
    }
}

final class LoaderSpy {
    private(set) var loadCallCount = 0
    
    func load() {
        loadCallCount += 1
    }
}

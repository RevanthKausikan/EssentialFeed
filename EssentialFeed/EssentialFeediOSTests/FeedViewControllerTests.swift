//
//  FeedViewControllerTests.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 18/03/25.
//

import Testing
import UIKit

final class FeedViewController: UIViewController {
    private var loader: LoaderSpy?
    
    convenience init(loader: LoaderSpy) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader?.load()
    }
}

@MainActor
final class FeedViewControllerTests: EFTesting {
    @Test("Init does not load feed")
    func init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        
        #expect(loader.loadCallCount == 0)
    }
    
    @Test("ViewDidLoad loads feed")
    func viewDidLoad_loadsFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        
        #expect(loader.loadCallCount == 1)
    }
}

final class LoaderSpy {
    private(set) var loadCallCount = 0
    
    func load() {
        loadCallCount += 1
    }
}

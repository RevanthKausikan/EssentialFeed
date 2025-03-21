//
//  FeedUIIntegrationTests+LoaderSpy.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import EssentialFeed
import EssentialFeediOS

extension FeedUIIntegrationTests {
    final class LoaderSpy: FeedLoader, FeedImageDataLoader {
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
        
        // MARK: - FeedImageDataLoader
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
}

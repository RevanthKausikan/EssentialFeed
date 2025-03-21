//
//  FeedUIComposer.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import EssentialFeed
import UIKit

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = { [weak feedController] feed in
            feedController?.tableModel = feed.map { model in
                FeedImageCellController(cellModel: model, imageLoader: imageLoader)
            }
        }
        return feedController
    }
}

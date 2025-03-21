//
//  FeedImageCell+TestHelpers.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import UIKit
import EssentialFeediOS

extension FeedImageCell {
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

//
//  FeedImageCellController.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

import UIKit


protocol FeedImageCellControllerDelegate {
    func didRequestImage()
    func didCancelImageRequest()
}

final class FeedImageCellController {
    private let delegate: FeedImageCellControllerDelegate
    private var cell: FeedImageCell?
    
    init(delegate: FeedImageCellControllerDelegate) {
        self.delegate = delegate
    }
    
    func view(in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell") as! FeedImageCell
        self.cell = cell
        delegate.didRequestImage()
        return cell
    }
    
    func preload() {
        delegate.didRequestImage()
    }
    
    func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelImageRequest()
    }
}

extension FeedImageCellController: FeedImageView {
    func display(_ model: FeedImageViewModel<UIImage>) {
        cell?.locationContainer.isHidden = !model.hasLocation
        cell?.locationLabel.text = model.location
        cell?.descriptionLabel.text = model.description
        cell?.feedImageView.image = model.image
        cell?.feedImageContainer.isShimmering = model.isLoading
        cell?.feedImageRetryButton.isHidden = !model.shouldRetry
        cell?.onRetry = delegate.didRequestImage
    }
    
    private func releaseCellForReuse() {
        cell = nil
    }
}

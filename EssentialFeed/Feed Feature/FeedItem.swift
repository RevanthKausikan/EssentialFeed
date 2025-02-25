//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 24/02/25.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let url: URL
}

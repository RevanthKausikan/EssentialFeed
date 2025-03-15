//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 09/03/25.
//

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}

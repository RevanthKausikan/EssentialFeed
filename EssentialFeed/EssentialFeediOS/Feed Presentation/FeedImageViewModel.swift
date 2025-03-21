//
//  FeedImageViewModel 2.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 21/03/25.
//

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool { location != nil }
}

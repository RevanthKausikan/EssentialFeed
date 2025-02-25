//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Revanth Kausikan on 25/02/25.
//

struct FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    struct RemoteFeedItem: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        var asFeedItem: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: url)
        }
    }
    
    private static var OK_200: Int { 200 }
    
    static func map(data: Data, response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else { throw RemoteFeedLoader.Error.invalidData }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map { $0.asFeedItem }
    }
}

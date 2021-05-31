//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/30.
//

import Foundation

internal struct FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
    }
    
    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var feedItem: FeedItem {
            FeedItem(id: id,
                     description: description,
                     location: location,
                     imageURL: image
            )
        }
    }
    
    private static var OK_200: UInt { 200 }
    
    internal static func map(data: Data, response: HTTPURLResponse) -> LoadFeedResult {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        
        let items = root.items.map { $0.feedItem }
        return .success(items)
    }
}

//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/30.
//

import Foundation

internal struct FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    private static var OK_200: UInt { 200 }
    
    internal static func map(data: Data, response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}

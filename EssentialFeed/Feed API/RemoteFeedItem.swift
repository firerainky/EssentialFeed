//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/6/4.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}

//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/26.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    public init(id: UUID, description: String?, location: String?, image: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.image = image
    }
}

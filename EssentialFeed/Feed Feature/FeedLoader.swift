//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/26.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: (LoadFeedResult) -> Void)
}

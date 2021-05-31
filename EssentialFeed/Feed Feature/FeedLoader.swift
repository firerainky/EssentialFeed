//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/26.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

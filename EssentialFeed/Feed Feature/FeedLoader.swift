//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/26.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], Error>

public protocol FeedLoader {
    
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

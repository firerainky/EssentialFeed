//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/5.
//

import Foundation
import EssentialFeed

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    
    func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    let models = [uniqueImage(), uniqueImage()]
    let locals = models.map {
        LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
    }
    return (models: models, local: locals)
}

extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .second, value: seconds, to: self)!
    }
}

//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/6/4.
//

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public typealias SaveResult = Error?
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items.toLocal(), completion: completion)
            }
        }
    }
    
    private func cache(_ items: [LocalFeedItem], completion: @escaping (SaveResult) -> Void) {
        store.insert(items: items, time: currentDate(), completion: { [weak self] error in
            guard self != nil else { return }
            completion(error)
        })
    }
}

extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        map {
            LocalFeedItem(id: $0.id,
                          description: $0.description,
                          location: $0.location,
                          imageURL: $0.imageURL
            )
        }
    }
}

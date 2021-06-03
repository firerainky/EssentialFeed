//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/3.
//

import Foundation
import XCTest
import EssentialFeed

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    private var deletionCompletions = [DeletionCompletion]()
    
    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert(items: [FeedItem], timestamp: Date)
    }
    
    var receiveMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        receiveMessages.append(.deleteCacheFeed)
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem], time: Date) {
        receiveMessages.append(.insert(items: items, timestamp: time))
    }
}

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, time: currentDate())
            }
        }
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receiveMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        sut.save(items)
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        
        sut.save(items)
        store.completeDeletion(with: anyNSError())
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestsCacheInsertionWithTempstampOnSuccessfulDeletion () {
        let items = [uniqueItem(), uniqueItem()]
        let currentTime = Date()
        let (sut, store) = makeSUT {
            currentTime
        }
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed, .insert(items: items, timestamp: currentTime)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = { Date() },
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(store, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        URL(string: "https://a-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

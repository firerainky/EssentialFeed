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
    var deleteCacheFeedCallCount = 0
    var insertCallCount = 0
    
    func completeDeletion(with: Error, at index: Int = 0) {
        
    }
}

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCacheFeedCallCount += 1
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deleteCacheFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        sut.save(items)
        
        XCTAssertEqual(store.deleteCacheFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        
        sut.save(items)
        store.completeDeletion(with: anyNSError())
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
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

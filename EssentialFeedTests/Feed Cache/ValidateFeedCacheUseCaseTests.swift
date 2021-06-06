//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/5.
//

import XCTest
import EssentialFeed

class ValidateFeedCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receiveMessages, [])
    }
    
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        XCTAssertEqual(store.receiveMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteNonExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let nonExpiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    func test_validateCache_deletesCacheOnExpiration() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.receiveMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_deletesExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receiveMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_doesNotDeleteInvalidCacheAfterInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        sut = nil
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(store, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
}

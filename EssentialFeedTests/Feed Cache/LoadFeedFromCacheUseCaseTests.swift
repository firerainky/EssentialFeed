//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/5.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receiveMessages, [])
    }
    
    func test_load_requestsCacheRetrieve() {
        let (sut, store) = makeSUT()
        sut.load() { _ in }
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let error = anyNSError()
        let (sut, store) = makeSUT()
        
        expect(sut, toCompletionWith: .failure(error)) {
            store.completeRetrieval(with: error)
        }
    }
    
    func test_load_deliversNoImageOnEmptyCacheStore() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompletionWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }
    
    func test_load_deliversCachedImagesOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let nonExpiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        expect(sut, toCompletionWith: .success(feed.models)) {
            store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        }
    }
    
    func test_load_doesNotDeliverCachedImageOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        expect(sut, toCompletionWith: .success([])) {
            store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
        }
    }
    
    func test_load_doesNotDeliverCachedImageOnExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        expect(sut, toCompletionWith: .success([])) {
            store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
        }
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.load(completion: { _ in })
        store.completeRetrieval(with: anyNSError())
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.load(completion: { _ in })
        store.completeRetrievalWithEmptyCache()
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let nonExpiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnExpiredCache() {
        let feed = uniqueImageFeed()
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(days: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load(completion: { _ in })
        store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receiveMessages, [.retrieve])
    }
    
    func test_load_doesNotDeliverResultAfterInstanceHasBeendeallocated () {

        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init )
        var receivedResults = [LocalFeedLoader.LoadResult]()
        
        sut?.load(completion: { result in receivedResults.append(result) })
        sut = nil
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Helpers
    private func expect(_ sut: LocalFeedLoader,
                        toCompletionWith expectedResult: LocalFeedLoader.LoadResult,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        sut.load() { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead.", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
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

//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/3.
//

import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receiveMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        sut.save(uniqueImageFeed().models) { _ in }
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        
        sut.save(uniqueImageFeed().models) { _ in }
        store.completeDeletion(with: anyNSError())
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestsCacheInsertionWithTempstampOnSuccessfulDeletion () {
        let feed = uniqueImageFeed()
        let currentTime = Date()
        
        let (sut, store) = makeSUT {
            currentTime
        }
        
        sut.save(feed.models) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed, .insert(feed: feed.local, timestamp: currentTime)])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        
        expect(sut, toCompletionWithError: error) {
            store.completeDeletion(with: error)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        
        expect(sut, toCompletionWithError: error) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: error)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompletionWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedError = [Error?]()
        sut?.save([], completion: { receivedError.append($0) })
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedError.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedError = [LocalFeedLoader.SaveResult]()
        sut?.save([], completion: { receivedError.append($0) })
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedError.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompletionWithError expectedError: NSError?,
                        when action: () -> Void) {
        
        var receivedError: Error?
        let exp = expectation(description: "Wait for save completion.")
        
        sut.save(uniqueImageFeed().models) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError)
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
    
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        
        func uniqueImage() -> FeedImage {
            FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
        }
        
        let models = [uniqueImage(), uniqueImage()]
        let locals = models.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (models: models, local: locals)
    }
    
    private func anyURL() -> URL {
        URL(string: "https://a-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/3.
//

import Foundation
import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receiveMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        sut.save(uniqueItems().models) { _ in }
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        
        sut.save(uniqueItems().models) { _ in }
        store.completeDeletion(with: anyNSError())
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestsCacheInsertionWithTempstampOnSuccessfulDeletion () {
        let items = uniqueItems()
        let currentTime = Date()
        
        let (sut, store) = makeSUT {
            currentTime
        }
        
        sut.save(items.models) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed, .insert(items: items.local, timestamp: currentTime)])
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
    
    private class FeedStoreSpy: FeedStore {
        
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [DeletionCompletion]()
        
        enum ReceivedMessage: Equatable {
            case deleteCacheFeed
            case insert(items: [LocalFeedItem], timestamp: Date)
        }
        
        var receiveMessages = [ReceivedMessage]()
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            receiveMessages.append(.deleteCacheFeed)
            deletionCompletions.append(completion)
        }
        
        func insert(items: [LocalFeedItem], time: Date, completion: @escaping InsertionCompletion) {
            receiveMessages.append(.insert(items: items, timestamp: time))
            insertionCompletions.append(completion)
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompletionWithError expectedError: NSError?,
                        when action: () -> Void) {
        
        var receivedError: Error?
        let exp = expectation(description: "Wait for save completion.")
        
        sut.save(uniqueItems().models) { error in
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
    
    private func uniqueItems() -> (models: [FeedItem], local: [LocalFeedItem]) {
        
        func uniqueItem() -> FeedItem {
            FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
        }
        
        let models = [uniqueItem(), uniqueItem()]
        let locals = models.map {
            LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)
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

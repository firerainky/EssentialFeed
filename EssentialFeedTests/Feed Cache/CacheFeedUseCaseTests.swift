//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/3.
//

import Foundation
import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.store.insert(items: items, time: self.currentDate(), completion: { [weak self] error in
                    guard self != nil else { return }
                    completion(error)
                })
            } else {
                completion(error)
            }
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(items: [FeedItem], time: Date, completion: @escaping InsertionCompletion)
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receiveMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        
        sut.save(items) { _ in }
        store.completeDeletion(with: anyNSError())
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestsCacheInsertionWithTempstampOnSuccessfulDeletion () {
        let items = [uniqueItem(), uniqueItem()]
        let currentTime = Date()
        let (sut, store) = makeSUT {
            currentTime
        }
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receiveMessages, [.deleteCacheFeed, .insert(items: items, timestamp: currentTime)])
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
        
        var receivedError = [Error?]()
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
            case insert(items: [FeedItem], timestamp: Date)
        }
        
        var receiveMessages = [ReceivedMessage]()
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            receiveMessages.append(.deleteCacheFeed)
            deletionCompletions.append(completion)
        }
        
        func insert(items: [FeedItem], time: Date, completion: @escaping InsertionCompletion) {
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
        
        sut.save([uniqueItem()]) { error in
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

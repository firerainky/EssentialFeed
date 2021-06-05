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
        
        var receivedError: Error?
        let exp = expectation(description: "Wait for load completion")
        sut.load() { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got \(result) instead")
            case let .failure(error):
                receivedError = error
            }
            exp.fulfill()
        }
        store.completeRetrieval(with: error)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(error, receivedError as NSError?)
    }
    
    func test_load_deliversNoImageOnEmptyCacheStore() {
        let (sut, store) = makeSUT()

        var receivedImages: [FeedImage]?
        let exp = expectation(description: "Wait for load completion")
        sut.load() { result in
            switch result {
            case let .success(images):
                receivedImages = images
            case .failure:
                XCTFail("Expected success, got \(result) instead.")
            }
            exp.fulfill()
        }
        store.completeRetrievalWithEmptyCache()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedImages, [])
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
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

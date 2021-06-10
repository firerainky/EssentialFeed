//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/9.
//

import XCTest
import EssentialFeed

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let _ = makeSUT()
//        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {

    }

    func test_insert_deliversNoErrorOnEmptyCache() {

    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {

    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {

    }

    func test_delete_deliversNoErrorOnEmptyCache() {

    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {

    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {

    }

    func test_delete_emptiesPriouslyInsertedCache() {

    }

    func test_storeSideEffects_runSerially() {

    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let sut = CoreDataFeedStore()
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
}

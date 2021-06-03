//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/5/26.
//

import Foundation
import XCTest
import EssentialFeed

class LoadFeedRemoteUseCaseTests: XCTestCase {
    
    func test_init_doesNotCallLoad() {
        let (_, client) = makeSUT()
        XCTAssertEqual(client.requestedURLs.count, 0)
    }
    
    func test_loads_clientGetsURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load() { _ in }
        XCTAssertEqual(client.requestedURLs.count, 1)
        XCTAssertEqual(client.requestedURLs.first, url)
    }
    
    func test_loads_deliversErrorOnConnectionError() {
        let (sut, client) = makeSUT()
        
        expect(sut: sut, with: failure(.connectivity)) {
            client.complete(with: NSError(domain: "RemoteFeedLoader", code: 0, userInfo: nil))
        }
    }
    
    func test_loads_deliversErrorOnNot200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 403, 404, 500].enumerated()
        samples.forEach { index, statusCode in
            let jsonData = makeJSONData(for: [])
            expect(sut: sut, with: failure(.invalidData)) {
                client.complete(withStatusCode: statusCode, data: jsonData, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJson() {
        let (sut, client) = makeSUT()
        
        expect(sut: sut, with: failure(.invalidData)) {
            let invalidJson = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsonList() {
        let (sut, client) = makeSUT()
        expect(sut: sut, with: .success([])) {
            let emptyJsonData = makeJSONData(for: [])
            client.complete(withStatusCode: 200, data: emptyJsonData)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJsonItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(id: UUID(), imageURL: URL(string: "https://a-url.com")!)
        
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://another-url.com")!)
        
        let models = [item1.model, item2.model]
        expect(sut: sut, with: .success(models), when: {
            let data = makeJSONData(for: [item1.json, item2.json])
            client.complete(withStatusCode: 200, data: data)
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let url = URL(string: "https://a-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { result in
            capturedResults.append(result)
        }
        sut = nil
        
        let data = makeJSONData(for: [])
        client.complete(withStatusCode: 200, data: data)
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    
    // MARK: Test Helpers
    
    private func expect(
        sut: RemoteFeedLoader,
        with expectedResult: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion.")
        sut.load { result in
            switch(result, expectedResult) {
            case let (.success(items), .success(expectedItems)):
                XCTAssertEqual(items, expectedItems, file: file, line: line)
            case let (.failure(error as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(error, expectedError, file: file, line: line)
            default:
                XCTFail("Expect \(expectedResult) but get \(result) instead.", file: file, line: line)
            }
            
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> LoadFeedResult {
        .failure(error)
    }
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!,
                 client: HTTPClientSpy = HTTPClientSpy(),
                 file: StaticString = #filePath,
                 line: UInt = #line
    ) -> (RemoteFeedLoader, HTTPClientSpy) {
        let sut = RemoteFeedLoader(url: url, client: client)
        
        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(client, file: file, line: line)
        return (sut, client)
    }
    
    private func makeItem(id: UUID,
                  description: String? = nil,
                  location: String? = nil,
                  imageURL: URL)
    -> (model: FeedItem, json: [String: Any]) {
        
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { result, e in
            if let value = e.value {
                result[e.key] = value
            }
        }
        
        return (item, json)
    }
    
    private func makeJSONData(for objs: [[String: Any]]) -> Data {
        let json = ["items": objs]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )
            messages[index].completion(.success(data: data, response: response!))
        }
    }
}

//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/5/26.
//

/**
## Load Feed Use Case

### Data (Input):

-   URL

### Primary course (happy path):

1.  Execute "Load Feed Items" command with above data.
2.  System downloads data from the URL.
3.  System validates downloaded data.
4.  System creates feed items from valid data.
5.  System delivers feed items.

### Invalid data – error course (sad path):

1.  System delivers error.

### No connectivity – error course (sad path):

1.  System delivers error.
 */

import Foundation
import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
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
        
        expect(sut: sut, with: .failure(.connectivity)) {
            client.complete(with: NSError(domain: "RemoteFeedLoader", code: 0, userInfo: nil))
        }
    }
    
    func test_loads_deliversErrorOnNot200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 403, 404, 500].enumerated()
        samples.forEach { index, statusCode in
            expect(sut: sut, with: .failure(.invalidData)) {
                client.complete(withStatusCode: statusCode, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJson() {
        let (sut, client) = makeSUT()
        
        expect(sut: sut, with: .failure(.invalidData)) {
            let invalidJson = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsonList() {
        let (sut, client) = makeSUT()
        expect(sut: sut, with: .success([])) {
            let emptyJsonData = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyJsonData)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJsonItems() {
        let (sut, client) = makeSUT()
        
        let item1 = FeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "https://a-url.com")!)
        
        let item2 = FeedItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://another-url.com")!)
        
        let item1Json = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]
        
        let item2Json = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.absoluteString
        ]
        
        let itemsJson = [
            "items": [item1Json, item2Json]
        ]
                             
        expect(sut: sut, with: .success([item1, item2]), when: {
            let jsonData = try! JSONSerialization.data(withJSONObject: itemsJson)
            client.complete(withStatusCode: 200, data: jsonData)
        })
    }
    
    
    // MARK: Test Helpers
    
    private func expect(
        sut: RemoteFeedLoader,
        with result: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line) {
        
        var capturedErrors = [RemoteFeedLoader.Result]()
        sut.load { result in
            capturedErrors.append(result)
        }
        action()
        XCTAssertEqual(capturedErrors, [result], file: file, line: line)
    }
    
    func makeSUT(url: URL = URL(string: "https://a-url.com")!,
                 client: HTTPClientSpy = HTTPClientSpy()
    ) -> (RemoteFeedLoader, HTTPClientSpy) {
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    class HTTPClientSpy: HTTPClient {
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
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
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

//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/5/31.
//

import Foundation
import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask
}

protocol HTTPSessionDataTask {
    func resume()
}

class URLSeesionHTTPClient: HTTPClient {
    var session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url, completionHandler: { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }).resume()
    }
}

class URLSeesionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_resumeDataTaskWithURL() {
        let url = URL(string: "https://a-url.com")!
        let session = HTTPSessionSpy()
        let task = HTTPSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSeesionHTTPClient(session: session)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumedCount, 1)
    }
    
    func test_getFromURL_getFailureOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let session = HTTPSessionSpy()
        let task = HTTPSessionDataTaskSpy()
        let error = NSError(domain: "any error", code: 1, userInfo: nil)
        session.stub(url: url, task: task, error: error)
        let sut = URLSeesionHTTPClient(session: session)
        
        let exp = expectation(description: "Wait for get completion.")
        
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected failure with error \(error), got \(result) instead.")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    class HTTPSessionSpy: HTTPSession {
        var requestedURLs = [URL]()
        private var stubs = [URL : Stub]()
        
        private struct Stub {
            var task: HTTPSessionDataTask
            var error: Error?
        }
        
        func stub(url: URL, task: HTTPSessionDataTask = FakeHTTPSessionDataTask(), error: Error? = nil) {
            let stub = Stub(task: task, error: error)
            stubs[url] = stub
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask {
            self.requestedURLs.append(url)
            guard let stub = stubs[url] else {
                fatalError("Can not find the stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
    class FakeHTTPSessionDataTask: HTTPSessionDataTask {
        func resume() { }
    }
    class HTTPSessionDataTaskSpy: HTTPSessionDataTask {
        var resumedCount = 0
        func resume() {
            resumedCount += 1
        }
    }
}

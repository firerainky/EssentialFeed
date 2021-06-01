//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/5/31.
//

import Foundation
import XCTest
import EssentialFeed

class URLSessionHTTPClient: HTTPClient {
    var session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private class UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url, completionHandler: { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data: data, response: response))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }).resume()
    }
}

class URLSeesionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performGetRequestWithURL() {

        let url = anyURL()
        let exp = expectation(description: "Wait for observing request complete.")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: anyURL()) { _ in }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_getFailureOnRequestError() {
        let requestError = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as NSError?
        XCTAssertNotNil(receivedError)
        XCTAssertEqual(receivedError!.domain, requestError.domain)
        XCTAssertEqual(receivedError!.code, requestError.code)
    }
    
    func test_getFromURL_getFailureOnInvalidValues() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_getDataAndResponseOnValidValues() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        let result = resultValuesFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(result?.data, data)
        XCTAssertEqual(result?.response.url, response.url)
        XCTAssertEqual(result?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        
        let result = resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(result?.data, emptyData)
        XCTAssertEqual(result?.response.url, response.url)
        XCTAssertEqual(result?.response.statusCode, response.statusCode)
        
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead.", file: file, line: line)
            return nil
        }
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        
        switch result {
        case let .success(data: data, response: response):
            return (data, response)
        default:
            XCTFail("Expected failure, got \(result) instead.", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult {
        
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for get completion.")
        var receivedResult: HTTPClientResult!
        
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private func anyURL() -> URL {
        URL(string: "https://a-url.com")!
    }
    
    private func anyData() -> Data {
        return Data("any data".utf8)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var observer: ((URLRequest) -> Void)?
        
        private struct Stub {
            var data: Data?
            var response: URLResponse?
            var error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(self)
            stub = nil
            observer = nil
        }
        
        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            self.observer = observer
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            observer?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}

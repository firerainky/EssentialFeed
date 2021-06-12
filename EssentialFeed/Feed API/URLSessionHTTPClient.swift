//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/6/1.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private class UnexpectedValuesRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url, completionHandler: { data, response, error in
            
            completion(Result {
                if let error = error {
                    throw error
                } else if let data = data, let response = response as? HTTPURLResponse {
                    return (data: data, response: response)
                } else {
                    throw UnexpectedValuesRepresentation()
                }
            })
        }).resume()
    }
}

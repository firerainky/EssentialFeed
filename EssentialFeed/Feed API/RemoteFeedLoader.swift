//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/27.
//

import Foundation

//public enum DataResult {
//    case success(Data)
//    case error(Error)
//}

public enum HTTPClientResult {
    case success(response: HTTPURLResponse, data: Data)
    case failure(Swift.Error)
}

public protocol HTTPClient {
    func get(from: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public class RemoteFeedLoader {
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    private var url: URL
    private var client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success(_, _):
                completion(.failure(.invalidData))
            case .failure(_):
                completion(.failure(.connectivity))
            }
        }
    }
}

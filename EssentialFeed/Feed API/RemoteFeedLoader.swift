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

public enum HTTPResult {
    case success(HTTPURLResponse)
    case failure(Swift.Error)
}

public protocol HTTPClient {
    func get(from: URL, completion: @escaping (HTTPResult) -> Void)
}

public class RemoteFeedLoader {
    
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
    
    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success(_):
                completion(.invalidData)
            case .failure(_):
                completion(.connectivity)
            }
        }
    }
}

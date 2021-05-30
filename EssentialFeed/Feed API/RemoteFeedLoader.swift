//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Zheng Kanyan on 2021/5/27.
//

import Foundation

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
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success(data, response):
                completion(FeedItemsMapper.map(data: data, response: response))
            case .failure(_):
                completion(.failure(.connectivity))
            }
        }
    }
}

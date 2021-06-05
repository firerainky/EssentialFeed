//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/6/5.
//

import Foundation

func anyURL() -> URL {
    URL(string: "https://a-url.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

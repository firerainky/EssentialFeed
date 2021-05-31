//
//  XCTCase_MemoryLeakTrackingHelper.swift
//  EssentialFeedTests
//
//  Created by Zheng Kanyan on 2021/5/31.
//

import Foundation
import XCTest

extension XCTestCase {
    func trackForMemoryLeak(_ obj: AnyObject, file: StaticString, line: UInt) {
        addTeardownBlock { [weak obj] in
            XCTAssertNil(obj, "Instance should be deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}

//
//  photobackupTests.swift
//  photobackupTests
//
//  Created by Sebastian Bohmann on 11.09.18.
//  Copyright © 2018 Sebastian Bohmann. All rights reserved.
//

import XCTest
@testable import photobackup

class photobackupTests: XCTestCase {
    var checksumString: String!
    var jsonRepresentation: String!
    var checksum: Checksum!
    
    override func setUp() {
        super.setUp()
        do {
            checksumString = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
            jsonRepresentation = "[\"" + checksumString.uppercased() + "\"]"
            checksum = try Checksum(checksumString: checksumString)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testChecksumToJson() throws {
        let value = [checksum]
        let data = try JSONEncoder().encode(value)
        let jsonRepresentation = String(data: data, encoding: .utf8)!
        XCTAssertEqual(self.jsonRepresentation, jsonRepresentation)
    }
    
    func testChecksumFromJson() throws {
        let value = try JSONDecoder().decode([Checksum].self, from: jsonRepresentation.data(using: .utf8)!)
        XCTAssertEqual(checksum, value.first!)
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}

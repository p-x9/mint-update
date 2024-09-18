//
//  MintUpdateTests.swift
//
//
//  Created by p-x9 on 2024/09/18
//  
//

import XCTest
@testable import mint_update

class MintUpdateTests: XCTestCase {
    func testPrereleaseCheck() {
        let prereleaseVersions = [
            "1.0.0-alpha",
            "1.0.0-alpha.1",
            "1.0.0-beta",
            "1.0.0-beta.2",
            "2.1.0-rc.1",
            "3.0.0-alpha+build123",
            "2.0.0-rc.3+meta",
            // not confirmed semantic versioning
            "1.0.0.alpha"
        ]

        let notPrereleaseVersions = [
            "1.0.0",
            "1.0.1",
            "2.0.0",
            "2.1.0",
            "3.0.0",
        ]

        for v in prereleaseVersions {
            XCTAssertTrue(v.isPrerelease, "\(v)")
        }

        for v in notPrereleaseVersions {
            XCTAssertFalse(v.isPrerelease, "\(v)")
        }
    }
}

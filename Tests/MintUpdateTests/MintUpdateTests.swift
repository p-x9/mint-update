//
//  MintUpdateTests.swift
//
//
//  Created by p-x9 on 2024/09/18
//  
//

import XCTest
@testable import MintUpdateUtil
import MintKit

class MintUpdateTests: XCTestCase {
    func testNormalizedVersion() {
        let sameVersions = [
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

        let invalidVersions = [
            "",
            "main",
        ]

        let versions = [
            "v1.0.0": "1.0.0",
            "v1.0.0-alpha": "1.0.0-alpha",
            "v1.0.0-alpha.1": "1.0.0-alpha.1",
            "v3.0.0-alpha+build123": "3.0.0-alpha+build123",
        ]

        for v in sameVersions {
            XCTAssertEqual(v, v.normalizedVersion)
        }

        for v in invalidVersions {
            XCTAssertNil(v.normalizedVersion)
        }

        for v in versions {
            XCTAssertEqual(v.key.normalizedVersion, v.value)
        }

    }

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

    func testFindVersion() throws {
        let dummy = Mint(path: .home, linkPath: .home)

        var tags = [
            "0.0.1",
            "1.0.0",
            "test",
            "2.0.0-rc.3+meta",
            "2.0.0"
        ]

        var map = dummy._tagVersionsMap(of: tags)

        XCTAssertEqual(
            dummy._findLatestVersion(
                from: map,
                usePrerelease: true
            ),
            "2.0.0"
        )

        XCTAssertEqual(
            dummy._findLatestVersion(
                from: map,
                usePrerelease: false
            ),
            "2.0.0"
        )

        tags.append("3.0.0-alpha")
        map = dummy._tagVersionsMap(of: tags)

        XCTAssertEqual(
            dummy._findLatestVersion(
                from: map,
                usePrerelease: true
            ),
            "3.0.0-alpha"
        )

        XCTAssertEqual(
            dummy._findLatestVersion(
                from: map,
                usePrerelease: false
            ),
            "2.0.0"
        )
    }
}

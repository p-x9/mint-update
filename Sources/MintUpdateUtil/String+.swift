//
//  String+.swift
//  
//
//  Created by p-x9 on 2024/09/18
//  
//

import Foundation

extension String {
    static let versionPattern = #"^\d+\.\d+\.\d+[A-Za-z0-9.+-]*$"#
    static var versionRegex: NSRegularExpression {
        try! .init(pattern: versionPattern)
    }

    /// Normalised version strings for semantic versioning rules.
    /// (This is not the case for the prerelease and build metadata parts.)
    ///
    /// Occasionally, there are cases where the version is prefixed with a ‘v’.
    ///    This does not conform to the rules of semantic versioning.
    package var normalizedVersion: String? {
        var string = self
        if string.starts(with: "v") { string.removeFirst() }
        let range = NSRange(string.startIndex ..< string.endIndex, in: string)
        if Self.versionRegex
            .firstMatch(in: string, options: [], range: range) != nil {
            return string
        }
        return nil
    }
}

extension String {
    static let prereleasePattern = #"^\d+\.\d+\.\d+[.+-][A-Za-z0-9.+-]+$"#
    static var prereleaseRegex: NSRegularExpression {
        try! .init(pattern: prereleasePattern)
    }

    package var isPrerelease: Bool {
        let range = NSRange(startIndex ..< endIndex, in: self)
        return Self.prereleaseRegex
            .firstMatch(in: self, options: [], range: range) != nil
    }
}

extension String {
    static let releasedVersionPattern = #"^\d+\.\d+\.\d"#
    static var releasedVersionRegex: NSRegularExpression {
        try! .init(pattern: releasedVersionPattern)
    }

    package var releasedVersion: String? {
        let range = NSRange(startIndex ..< endIndex, in: self)
        guard let result = Self.releasedVersionRegex
            .firstMatch(in: self, options: [], range: range) else {
            return nil
        }
        if let matchedRange = Range(result.range, in: self) {
            return String(self[matchedRange])
        }
        return nil
    }
}

extension String: LocalizedError {
    public var errorDescription: String? {
        self
    }
}

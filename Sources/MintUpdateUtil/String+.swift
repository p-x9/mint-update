//
//  String+.swift
//  
//
//  Created by p-x9 on 2024/09/18
//  
//

import Foundation

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

extension String: LocalizedError {
    public var errorDescription: String? {
        self
    }
}

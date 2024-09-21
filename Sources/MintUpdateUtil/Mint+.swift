//
//  Mint+.swift
//
//
//  Created by p-x9 on 2024/09/18
//  
//

import MintKit
import SwiftCLI

// MARK: - Package
extension Mint {
    struct Package {
        let repo: String
        let version: String

        var line: String {
            "\(repo)@\(version)"
        }
    }

    func packages(for mintfile: Mintfile) -> [PackageReference] {
        var mintfile = mintfile
        return withUnsafePointer(to: &mintfile) { ptr in
            let raw = UnsafeRawPointer(ptr)
            return raw.load(as: [PackageReference].self)
        }
    }
}

// MARK: - Update
extension Mint {
    typealias MintfileReplacement = (from: Package, to: Package)

    package func updateAll(usePrerelease: Bool) throws {
        guard mintFilePath.exists,
              let mintfile = try? Mintfile(path: mintFilePath) else {
            throw "🌱 mintfile not exists"
        }
        let packages = packages(for: mintfile)
        let replacements = packages.compactMap {
            replacement(for: $0, in: mintfile, usePrerelease: usePrerelease)
        }

        try updateMintfile(replacements)
    }

    package func update(_ name: String, usePrerelease: Bool) throws {
        guard mintFilePath.exists,
              let mintfile = try? Mintfile(path: mintFilePath) else {
            throw "🌱 mintfile not exists"
        }
        let packages = packages(for: mintfile)
            .filter {
                $0.name.contains(name)
            }

        if packages.isEmpty {
            throw "🌱 package named `\(name)` was not found"
        }

        let replacements = packages.compactMap {
            replacement(for: $0, in: mintfile, usePrerelease: usePrerelease)
        }

        try updateMintfile(replacements)
    }

    private func replacement(
        for package: PackageReference,
        in mintfile: Mintfile,
        usePrerelease: Bool
    ) -> MintfileReplacement? {
        guard !["master", "develop", "main"].contains(package.version),
              !package.version.isEmpty else {
            return nil
        }
        guard let latest = try? findLatestVersion(for: package, usePrerelease: usePrerelease),
              package.version != latest else {
            return nil
        }
        let from = Package(repo: package.repo, version: package.version)
        let to = Package(repo: package.repo, version: latest)
        return (from, to)
    }

    private func updateMintfile(_ replacements: [MintfileReplacement]) throws {
        var string: String = try mintFilePath.read()
        for replacement in replacements {
            print("🌱 bump \(replacement.from.repo) from \(replacement.from.version) to \(replacement.to.version)")
            string = string.replacingOccurrences(
                of: replacement.from.line,
                with: replacement.to.line
            )
        }

        try mintFilePath.write(string, encoding: .utf8)
    }
}


// MARK: - Find Version
extension Mint {
    func findLatestVersion(
        for package: PackageReference,
        usePrerelease: Bool
    ) throws -> String? {
        let tagOutput = try Task.capture(
            bash: "git ls-remote --tags --refs \(package.gitPath)"
        )
        let tagReferences = tagOutput.stdout
        let tags = tagReferences
            .split(separator: "\n")
            .map {
                String(
                    $0.split(separator: "\t")
                    .last!
                    .split(separator: "/")
                    .last!
                )
            }

        var tagsMap: [String: String] = .init(
            uniqueKeysWithValues: tags.compactMap {
                if let normalized = $0.normalizedVersion {
                    return ($0, normalized)
                }
                return nil
            }
        )

        if !usePrerelease {
            tagsMap = tagsMap.filter { !$1.isPrerelease }
        }

        return tagsMap
            .sorted {
                $0.value.compare($1.value, options: .numeric) == .orderedAscending
            }
            .last?
            .value
    }
}

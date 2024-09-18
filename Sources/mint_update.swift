import Foundation
import ArgumentParser
import MintKit
import PathKit
import SwiftCLI

@main
struct mint_update: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "mint-update",
        abstract: "Updates version of the package defined in the `Mintfile`",
        shouldDisplay: true,
        helpNames: [.long, .short]
    )

    @ArgumentParser.Option(
        help: "Package Name"
    )
    var name: String?

    @ArgumentParser.Flag(
        name: .customLong("all"),
        help: "Update All Packages"
    )
    var shouldUpdateAll: Bool = false

    @ArgumentParser.Option(
        name: [.customShort("m"), .customLong("mintfile")],
        help: "Custom path to a Mintfile."
    )
    var mintFile: String = "Mintfile"

    @ArgumentParser.Flag(
        name: .customLong("prerelease"),
        help: "Use the Prerelease version. (alpha, beta, ...)"
    )
    var usePrerelease: Bool = false

    mutating func run() throws {
        let mint = Mint(
            path: mintPath,
            linkPath: linkPath,
            mintFilePath: .init(mintFile)
        )

        if shouldUpdateAll {
            try mint.updateAll(usePrerelease: usePrerelease)
        } else if let name {
            try mint.update(name, usePrerelease: usePrerelease)
        } else {
            print(
                Self.helpMessage()
            )
            throw "Please specify package name"
        }
    }
}

extension mint_update {
    var mintPath: Path {
        var mintPath: Path = "~/.mint"
        if let path = ProcessInfo.processInfo.environment["MINT_PATH"], !path.isEmpty {
            mintPath = Path(path)
        }
        return mintPath
    }

    var linkPath: Path {
        var linkPath: Path = "~/.mint/bin"
        if let path = ProcessInfo.processInfo.environment["MINT_LINK_PATH"], !path.isEmpty {
            linkPath = Path(path)
        }
        return linkPath
    }
}

extension Mint {
    struct Package {
        let repo: String
        let version: String

        var line: String {
            "\(repo)@\(version)"
        }
    }
    typealias MintfileReplacement = (from: Package, to: Package)

    func updateAll(usePrerelease: Bool) throws {
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

    func update(_ name: String, usePrerelease: Bool) throws {
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

extension Mint {
    func packages(for mintfile: Mintfile) -> [PackageReference] {
        var mintfile = mintfile
        return withUnsafePointer(to: &mintfile) { ptr in
            let raw = UnsafeRawPointer(ptr)
            return raw.load(as: [PackageReference].self)
        }
    }
}

extension Mint {
    func findLatestVersion(
        for package: PackageReference,
        usePrerelease: Bool
    ) throws -> String? {
        let tagOutput = try Task.capture(
            bash: "git ls-remote --tags --refs \(package.gitPath)"
        )
        let tagReferences = tagOutput.stdout
        var tags = tagReferences
            .split(separator: "\n")
            .map {
                String(
                    $0.split(separator: "\t")
                    .last!
                    .split(separator: "/")
                    .last!
                )
            }

        if !usePrerelease {
            tags = tags.filter { !$0.isPrerelease }
        }

        tags.sort { $0.compare($1, options: .numeric) == .orderedAscending }

        return tags.last
    }
}

extension String {
    static let prereleasePattern = #"^\d+\.\d+\.\d*[.-][A-Za-z0-9.-]+$"#
    static var prereleaseRegex: NSRegularExpression {
        try! .init(pattern: prereleasePattern)
    }

    var isPrerelease: Bool {
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

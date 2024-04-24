import Foundation
import ArgumentParser
import MintKit
import PathKit
import SwiftCLI

@main
struct mint_update: ParsableCommand {
    mutating func run() throws {
        let mint = Mint(path: mintPath, linkPath: linkPath)
        try mint.update()
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
    typealias MintfileReplacement = (from: String, to: String)

    func update() throws {
        guard mintFilePath.exists,
              let mintfile = try? Mintfile(path: mintFilePath) else {
            return
        }
        let packages = packages(for: mintfile)
        let replacements = packages.compactMap {
            update(for: $0, in: mintfile)
        }

        var string: String = try mintFilePath.read()
        for replacement in replacements {
            string = string.replacingOccurrences(
                of: replacement.from,
                with: replacement.to
            )
        }

        try mintFilePath.write(string, encoding: .utf8)
    }

    func update(
        for package: PackageReference,
        in mintfile: Mintfile
    ) -> MintfileReplacement? {
        guard !["master", "develop", "main"].contains(package.version),
              !package.version.isEmpty else {
            return nil
        }
        guard let latest = try? findLatestVersion(for: package),
              package.version != latest else {
            return nil
        }
        let from = "\(package.repo)@\(package.version)"
        let to = "\(package.repo)@\(latest)"
        return (from, to)
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
        for package: PackageReference
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
        tags.sort { $0.compare($1, options: .numeric) == .orderedAscending }

        return tags.last
    }
}

import Foundation
import ArgumentParser
import MintKit
import PathKit
import MintUpdateUtil

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

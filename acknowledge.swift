#!/usr/bin/env xcrun swift -F Carthage/Build/Mac

import Foundation

protocol Streamable {
    var title: String { get }
    var body: String { get }
}

extension Streamable {
    var writableString: String {
        return "# \(title)\n\n\(body)"
    }
}

struct License: Streamable, Hashable {
    let libraryName: String
    let legalText: String

    var title: String {
        return libraryName
    }

    var body: String {
        return legalText
    }
}

func == (left: License, right: License) -> Bool {
    return left.libraryName == right.libraryName
}

func getLicense(_ URL: URL) throws -> License {
    var legalText = try String(contentsOf: URL, encoding: .utf8)
    let pathComponents = URL.pathComponents
    let libraryName = pathComponents[pathComponents.count - 2]
    legalText = legalText.replacingOccurrences(of: "# ", with: "")
    legalText = legalText.replacingOccurrences(of: "**", with: "")
    return License(libraryName: libraryName, legalText: legalText)
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

func run() throws {

    let carthageDir = "Carthage"
    let outputFile = "LICENSES.md"
    let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles]

    let fileManager = FileManager.default

    // Get URL’s for all files in carthageDir

    guard let carthageDirURL = URL(string: carthageDir),
        let carthageEnumerator = fileManager.enumerator(at: carthageDirURL, includingPropertiesForKeys: nil, options: options, errorHandler: nil)
        else {
            print("Error: \(carthageDir) directory not found. Please run `rake`")
            return
    }

    guard let carthageURLs = carthageEnumerator.allObjects as? [URL] else {
        print("Unexpected error: Enumerator contained item that is not URL.")
        return
    }

    let allURLs = carthageURLs

    // Get just the LICENSE files and convert them to License structs

    let licenseURLs = allURLs.filter { url in
        let pods = url.pathComponents.filter { $0 == "Pods" }
        if !pods.isEmpty {
            return false
        }
        return url.lastPathComponent.range(of: "LICENSE") != nil || url.lastPathComponent.range(of: "LICENCE") != nil
    }

    var licenses = licenseURLs.compactMap { try? getLicense($0) }
    licenses = licenses.unique()
    licenses = licenses.filter{ license -> Bool in
        return !license.legalText.isEmpty
    }
    licenses = licenses.filter{ license -> Bool in
        return !license.title.contains("QMobile")
    }
    licenses = licenses.sorted { (left, right) -> Bool in
        return left.title.compare(right.title).rawValue < 0
    }
    let html = licenses.map { $0.writableString }.joined(separator: "\n\n")
    try html.write(toFile: outputFile, atomically: false, encoding: .utf8)
}

func main() {
    do {
        try run()
    } catch let error as NSError {
        print(error.localizedDescription)
    }
}

main()

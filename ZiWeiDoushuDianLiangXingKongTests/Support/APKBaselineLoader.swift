import Foundation

private final class APKBaselineLoaderBundleToken: NSObject {}

enum APKBaselineLoaderError: Error {
    case fixtureNotFound(id: String)
    case decodeFailed(id: String, underlying: Error)
}

enum APKBaselineLoader {
    /// 同时兼容 Xcode 资源的子目录拷贝和扁平拷贝。
    private static let candidateSubdirectories: [String?] = [
        "Fixtures/APKBaselines",
        "APKBaselines",
        nil
    ]

    private static var bundle: Bundle {
        Bundle(for: APKBaselineLoaderBundleToken.self)
    }

    static func load(id: String, bundle: Bundle = APKBaselineLoader.bundle) throws -> APKBaselineCase {
        for subdirectory in candidateSubdirectories {
            if let url = bundle.url(forResource: id, withExtension: "json", subdirectory: subdirectory) {
                return try decodeFixture(at: url, expectedID: id)
            }
        }

        throw APKBaselineLoaderError.fixtureNotFound(id: id)
    }

    static func loadAll(bundle: Bundle = APKBaselineLoader.bundle) throws -> [APKBaselineCase] {
        var urls: [URL] = []
        var seenPaths = Set<String>()

        for subdirectory in candidateSubdirectories {
            let batch = bundle.urls(forResourcesWithExtension: "json", subdirectory: subdirectory) ?? []
            for url in batch where seenPaths.insert(url.path).inserted {
                urls.append(url)
            }
        }

        return try urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                try decodeFixture(at: url, expectedID: url.deletingPathExtension().lastPathComponent)
            }
    }

    private static func decodeFixture(at url: URL, expectedID: String) throws -> APKBaselineCase {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(APKBaselineCase.self, from: data)
        } catch {
            throw APKBaselineLoaderError.decodeFailed(id: expectedID, underlying: error)
        }
    }
}

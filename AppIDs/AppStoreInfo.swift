import SwiftUI

struct AppStoreInfo {
	let appName: String
	let iconURL: URL

	static func fetch(bundleID: String) async -> AppStoreInfo? {
		guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)&entity=software") else { return nil }
		do {
			let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad))
			struct Response: Decodable {
				struct Result: Decodable {
					let trackName: String
					let artworkUrl60: String
				}
				let results: [Result]
			}
			let decoded = try JSONDecoder().decode(Response.self, from: data)
			guard let first = decoded.results.first, let iconURL = URL(string: first.artworkUrl60) else { return nil }
			return AppStoreInfo(appName: first.trackName, iconURL: iconURL)
		} catch {
			return nil
		}
	}
}

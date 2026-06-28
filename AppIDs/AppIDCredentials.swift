import SwiftUI

struct AppIDCredentials: View {
	struct AppEntry: Identifiable {
		let id: String
		let domains: [String]
	}

	@State var response: [AppEntry] = []
	@State var error: Error?

	@State var searchText = ""

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/apple-appIDs-to-domains-shared-credentials.json")!

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			response = data
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	func silentReload() async {
		switch await Self.reload(cache: .reloadIgnoringLocalCacheData) {
		case let .success(data):
			withAnimation {
				response = data
				error = nil
			}
		case .failure:
			break
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<[AppEntry], Error> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: getURL, cachePolicy: cache))
			let dict = try JSONDecoder().decode([String: [String]].self, from: response)
			let entries = dict.sorted { $0.key < $1.key }.map { AppEntry(id: $0.key, domains: $0.value) }
			return .success(entries)
		} catch {
			return .failure(error)
		}
	}

	var body: some View {
		let responses = response
			.filter {
				searchText == "" ||
				$0.id.localizedCaseInsensitiveContains(searchText) ||
				$0.domains.joined(separator: "§").localizedCaseInsensitiveContains(searchText)
			}

		List {
			ForEach(responses) { entry in
				VStack(alignment: .leading, spacing: 2) {
					Text(entry.id)
					ForEach(entry.domains, id: \.self) { domain in
						Text(domain)
							.foregroundStyle(.secondary)
							.font(.caption)
					}
				}
				.multilineTextAlignment(.leading)
			}
		}
		.searchable(text: $searchText, prompt: Text("Search App IDs or Domains"))
		.refreshable {
			await reload()
		}
		.task {
			guard response.isEmpty else { return }
			await reload(cache: .returnCacheDataElseLoad)
			guard URLCache.shared.isStale(for: Self.getURL) else { return }
			await silentReload()
		}
		.navigationTitle(Text("App ID Credentials"))
		#if os(iOS)
			.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Local") {
	NavigationStack {
		AppIDCredentials(response: [
			.init(id: "P7SDVXUZPK.com.etrade.mobileproiphone", domains: ["etrade.com"]),
			.init(id: "com.example.App", domains: ["example.com", "example.net"]),
		])
	}
}

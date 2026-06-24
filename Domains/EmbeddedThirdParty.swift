import SwiftUI

struct EmbeddedThirdParty: View {
	@State var response: [String] = []
	@State var error: Error?

	@State var searchText = ""

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/websites-that-ask-for-credentials-for-other-services-when-embedded-as-third-party.json")!

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			response = data
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<[String], Error> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: getURL, cachePolicy: cache))
			let data = try JSONDecoder().decode([String].self, from: response)
			return .success(data)
		} catch {
			return .failure(error)
		}
	}

	var body: some View {
		let responses = response
			.filter { searchText == "" || $0.localizedCaseInsensitiveContains(searchText) }

		List {
			Section {
				Text("avoid incorrectly saving credentials that belong to a different service")
				Text("prevent associating the embedded domain's credentials with the parent page's account")
			} header: {
				Text("This list of embedded services is used to")
					.textCase(nil)
					.font(.caption)
			}
			.font(.caption)

			Section {
				ForEach(responses, id: \.hashValue) { response in
					Text(response)
				}
			} header: {} footer: {
				Text("Domains which, when embedded as a third party, ask for credentials belonging to a different service.")
			}
		}
		.searchable(text: $searchText, prompt: Text("Search Domains"))
		.refreshable {
			await reload()
		}
		.task {
			guard response.isEmpty else { return }
			await reload(cache: .returnCacheDataElseLoad)
		}
		.navigationTitle(Text("Embedded Third-Party"))
		#if os(iOS)
			.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Local") {
	NavigationStack {
		EmbeddedThirdParty(response: ["plaid.com", "schwab.com"])
	}
}

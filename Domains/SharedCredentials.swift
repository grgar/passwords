import SwiftUI

struct SharedCredentials: View {
	struct Entry: Codable, Hashable {
		var shared: [String]?
		var from: [String]?
		var to: [String]?
		var fromDomainsAreObsoleted: Bool?
	}

	@State var response: [Entry] = []
	@State var error: Error?

	@State var searchText = ""

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/shared-credentials.json")!

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			response = data
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<[Entry], Error> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: getURL, cachePolicy: cache))
			let data = try JSONDecoder().decode([Entry].self, from: response)
			return .success(data)
		} catch {
			return .failure(error)
		}
	}

	var body: some View {
		let responses = response
			.filter { searchText == "" || (($0.shared ?? []) + ($0.from ?? []) + ($0.to ?? [])).joined(separator: "§").localizedCaseInsensitiveContains(searchText) }

		List {
			Section {
				ForEach(responses.filter { $0.shared != nil }, id: \.hashValue) { response in
					if let shared = response.shared {
						VStack(alignment: .leading) {
							ForEach(shared, id: \.self) { shared in
								Text(shared)
							}
						}
						.multilineTextAlignment(.leading)
					}
				}
			} header: {
				Text("Shared")
			} footer: {
				Text("Domains whose credentials are all shared.")
			}

			Section {
				ForEach(responses.filter { $0.from != nil && $0.to != nil }, id: \.hashValue) { response in
					if let from = response.from, let to = response.to {
						LabeledContent {
							VStack(alignment: .trailing) {
								ForEach(from, id: \.self) { from in
									Text(from)
										.strikethrough(response.fromDomainsAreObsoleted ?? false)
								}
							}
							.multilineTextAlignment(.trailing)
						} label: {
							VStack(alignment: .leading) {
								ForEach(to, id: \.self) { to in
									Text(to)
								}
							}
							.multilineTextAlignment(.leading)
						}
					}
				}
			} header: {
				VStack(alignment: .leading) {
					Text("Transitioned")
					HStack {
						Text("New")
						Spacer()
						Text("Old")
					}
					.textCase(nil)
				}
			} footer: {
				Text("Credentials to be shared one-way.")
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
		.navigationTitle(Text("Shared Credentials"))
		#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Local") {
	NavigationStack {
		SharedCredentials(response: [
			.init(shared: ["example.com"]),
			.init(from: ["a.com"], to: ["b.com"], fromDomainsAreObsoleted: false),
			.init(from: ["a.com"], to: ["b.com"], fromDomainsAreObsoleted: true),
			.init(from: ["a.com", "b.com"], to: ["c.com"], fromDomainsAreObsoleted: true),
			.init(from: ["a.com", "b.com"], to: ["c.com", "d.com"], fromDomainsAreObsoleted: true),
			.init(from: ["a.com"], to: ["c.com", "d.com"], fromDomainsAreObsoleted: true),
			.init(shared: ["a.com", "b.com", "c.com", "d.com"]),
		])
	}
}

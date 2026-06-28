import SwiftUI

struct SharedCredentials: View {
	struct Entry: Codable, Hashable {
		var shared: [String]?
		var from: [String]?
		var to: [String]?
		var fromDomainsAreObsoleted: Bool?
	}

	@State var response: [Entry] = []
	@State var historicalResponse: [Entry] = []
	@State var error: Error?

	@State var searchText = ""

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/shared-credentials.json")!
	static let historicalURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/shared-credentials-historical.json")!

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		async let mainResult = Self.reload(cache: cache)
		async let historicalResult = Self.reloadFrom(Self.historicalURL, cache: cache)
		switch await mainResult {
		case let .success(data):
			response = data
			error = nil
		case let .failure(error):
			self.error = error
		}
		if case let .success(data) = await historicalResult {
			historicalResponse = data
		}
	}

	func silentReload() async {
		async let mainResult = Self.reload(cache: .reloadIgnoringLocalCacheData)
		async let historicalResult = Self.reloadFrom(Self.historicalURL, cache: .reloadIgnoringLocalCacheData)
		switch await mainResult {
		case let .success(data):
			withAnimation {
				response = data
				error = nil
			}
		case .failure:
			break
		}
		if case let .success(data) = await historicalResult {
			withAnimation { historicalResponse = data }
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<[Entry], Error> {
		await reloadFrom(getURL, cache: cache)
	}

	static func reloadFrom(_ url: URL, cache: NSURLRequest.CachePolicy) async -> Result<[Entry], Error> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: url, cachePolicy: cache))
			let data = try JSONDecoder().decode([Entry].self, from: response)
			return .success(data)
		} catch {
			return .failure(error)
		}
	}

	var body: some View {
		let domainFilter: (Entry) -> Bool = { entry in
			searchText == "" || ((entry.shared ?? []) + (entry.from ?? []) + (entry.to ?? [])).joined(separator: "§").localizedCaseInsensitiveContains(searchText)
		}
		let responses = response.filter(domainFilter)
		let historicalResponses = historicalResponse.filter(domainFilter)

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

			if !historicalResponses.isEmpty {
				Section {
					ForEach(historicalResponses.filter { $0.shared != nil }, id: \.hashValue) { response in
						if let shared = response.shared {
							LabeledContent {
								VStack(alignment: .trailing) {
									ForEach(shared, id: \.self) { shared in
										HStack {
											Spacer()
											Text(shared)
												.strikethrough()
										}
									}
								}
								.multilineTextAlignment(.trailing)
							} label: {
								Text("")
									.hidden()
							}
						}
					}
				} header: {
					Text("Historical")
				} footer: {
					Text("Formerly affiliated domains where password reuse warnings are suppressed but credentials are not shared.")
				}
			}
		}
		.searchable(text: $searchText, prompt: Text("Search Domains"))
		.refreshable {
			await reload()
		}
		.task {
			guard response.isEmpty else { return }
			await reload(cache: .returnCacheDataElseLoad)
			guard URLCache.shared.isStale(for: Self.getURL) else { return }
			await silentReload()
		}
		.navigationTitle(Text("Shared Credentials"))
		#if os(iOS)
		.listStyle(.inset)
		.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Local") {
	NavigationStack {
		SharedCredentials(
			response: [
				.init(shared: ["example.com"]),
				.init(from: ["a.com"], to: ["b.com"], fromDomainsAreObsoleted: false),
				.init(from: ["a.com"], to: ["b.com"], fromDomainsAreObsoleted: true),
				.init(from: ["a.com", "b.com"], to: ["c.com"], fromDomainsAreObsoleted: true),
				.init(from: ["a.com", "b.com"], to: ["c.com", "d.com"], fromDomainsAreObsoleted: true),
				.init(from: ["a.com"], to: ["c.com", "d.com"], fromDomainsAreObsoleted: true),
				.init(shared: ["a.com", "b.com", "c.com", "d.com"]),
			],
			historicalResponse: [
				.init(shared: ["old1.com", "old2.com"]),
				.init(shared: ["formerly-affiliated.com", "split-off.com"]),
			]
		)
	}
}

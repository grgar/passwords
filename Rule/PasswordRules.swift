import SwiftUI

struct PasswordRules: View {
	struct IngestRule: Codable {
		let rule: String

		enum CodingKeys: String, CodingKey {
			case rule = "password-rules"
		}
	}

	@State var response: [Rule] = []
	@State var error: DecodingError?

	@State var searchText = ""

	@State var showHelp = false

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/password-rules.json")!

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			response = data
				.map { Rule(domain: $0.key, rule: $0.value.rule) }
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<[String: IngestRule], DecodingError> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: getURL, cachePolicy: cache))
			let data = try JSONDecoder().decode([String: IngestRule].self, from: response)
			return .success(data)
		} catch {
			if let error = error as? DecodingError {
				return .failure(error)
			}
			return .failure(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unknown error", underlyingError: error)))
		}
	}

	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	private var isCompact: Bool { horizontalSizeClass == .compact }
	#else
	private let isCompact = false
	#endif

	@ScaledMetric(wrappedValue: 24, relativeTo: .body) private var faviconHeight

	var body: some View {
		let responses = response
			.sorted { $0.id.lexicographicallyPrecedes($1.id) }
			.filter { searchText == "" || $0.id.localizedCaseInsensitiveContains(searchText) }
		let isError = Binding(get: {
			error != nil
		}, set: {
			if !$0 {
				error = nil
			}
		})

		Group {
			if isCompact {
				List {
					ForEach(responses) { rule in
						NavigationLink {
							Text("Destination")
						} label: {
							Label {
								LabeledContent {} label: {
									Text(rule.id)
									PasswordRuleChips(rule: rule)
								}
							} icon: {
								Favicon(domain: rule.id)
							}
						}
					}
				}
				.listStyle(.plain)
			} else {
				Table(of: Rule.self) {
					TableColumn("Domain") { domain in
						Favicon(domain: domain.id)
					}
					TableColumn("id", value: \.id)
					TableColumn("id", value: \.id)
					TableColumn("id", value: \.id)
					TableColumn("id", value: \.id)
					TableColumn("id", value: \.id)
				} rows: {
					ForEach(responses) { rule in
						TableRow(rule)
					}
				}
			}
		}
		.searchable(text: $searchText, prompt: Text("Search Domains"))
		.alert(
			isPresented: isError,
			error: error,
			actions: {
				Button(role: .cancel) {
					error = nil
				} label: {
					Text("OK")
				}
				RefreshButton(isError: isError)
			}
		)
		.refreshable {
			await reload()
		}
		.task {
			guard response.isEmpty else { return }
			await reload(cache: .returnCacheDataElseLoad)
		}
		.navigationTitle(Text("Password Rules"))
	}
}

struct RefreshButton: View {
	@Binding var isError: Bool

	@Environment(\.refresh) private var refresh

	var body: some View {
		Button {
			isError = false
			Task {
				await refresh?()
			}
		} label: {
			Text("Retry")
		}
	}
}

#Preview("Local") {
	NavigationStack {
		PasswordRules(response: [.init(id: "example.com", originalRule: "maxlength: 5;")])
	}
}

#Preview("Remote") {
	NavigationStack {
		PasswordRules()
	}
}

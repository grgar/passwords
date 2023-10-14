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

	@AppStorage("showFavicon") private var showFavicon = true
	@ScaledMetric(wrappedValue: 24, relativeTo: .body) private var faviconHeight

	@State private var sortOrder = [KeyPathComparator(\Rule.id)]

	var body: some View {
		let responses = response
			.filter { searchText == "" || $0.id.localizedCaseInsensitiveContains(searchText) }
			.sorted(using: sortOrder)
		let isError = Binding(get: {
			error != nil
		}, set: {
			if !$0 {
				error = nil
			}
		})

		Group {
			#if os(tvOS)
			RulesList(rules: responses, showFavicon: showFavicon)
			#else
			if isCompact {
				RulesList(rules: responses, showFavicon: showFavicon)
			} else {
				RulesTable(rules: responses, showFavicon: showFavicon, faviconHeight: faviconHeight, sortOrder: $sortOrder)
			}
			#endif
		}
		.toolbar {
			ToolbarItemGroup(placement: .automatic) {
				Picker("Favicon", selection: $showFavicon) {
					Label("Show", systemImage: "checklist.unchecked").tag(true)
					Label("Hide", systemImage: "list.bullet").tag(false)
				}
				.pickerStyle(.segmented)
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
		#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
		#endif
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

struct RulesList: View {
	let rules: [Rule]
	let showFavicon: Bool

	var body: some View {
		List {
			ForEach(rules) { rule in
				NavigationLink {
					PasswordRuleDetail(rule: rule)
				} label: {
					Label {
						LabeledContent {} label: {
							Text(rule.id)
							PasswordRuleChips(rule: rule)
						}
					} icon: {
						if showFavicon {
							Favicon(domain: rule.id)
						}
					}
				}
			}
		}
		.listStyle(.plain)
	}
}

@available(tvOS, unavailable)
struct RulesTable: View {
	let rules: [Rule]
	let showFavicon: Bool
	let faviconHeight: Double
	@Binding var sortOrder: [KeyPathComparator<Rule>]

	@State private var selection: Rule.ID?

	var body: some View {
		Table(of: Rule.self, selection: $selection, sortOrder: $sortOrder) {
			TableColumn("Domain", value: \.id) { domain in
				HStack {
					if showFavicon {
						Favicon(domain: domain.id)
							.frame(maxHeight: faviconHeight)
					}
					Text(domain.id)
				}
			}

			TableColumn("Length", value: \.sumLength) { domain in
				if showFavicon {
					PasswordRuleChips.Length(min: domain.minLength, max: domain.maxLength)
						.symbolVariant(.fill)
						.symbolRenderingMode(.hierarchical)
						.font(.title)
				} else {
					Text("\(domain.minLength?.description ?? "?") – \(domain.maxLength?.description ?? "?")")
				}
			}
			.width(min: 48, ideal: 48, max: 64)

			TableColumn("Required") { domain in
				HStack {
					ForEach(domain.required.sorted()) { set in
						if let symbol = set.symbol {
							Image(systemName: symbol)
						} else {
							Text(set.description)
						}
					}
				}
			}
			TableColumn("Allowed") { domain in
				HStack {
					ForEach(domain.allowed.sorted()) { set in
						if let symbol = set.symbol {
							Image(systemName: symbol)
						} else {
							Text(set.description)
						}
					}
				}
			}
		} rows: {
			ForEach(rules) { rule in
				TableRow(rule)
			}
		}
		.navigationDestination(isPresented: Binding(get: { selection != nil }, set: { if !$0 { selection = nil } })) {
			if let rule = rules.first(where: { $0.id == selection }) {
				PasswordRuleDetail(rule: rule)
					.navigationSplitViewColumnWidth(min: 320, ideal: 640)
			}
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

#Preview("Table", traits: .fixedLayout(width: 960, height: 640)) {
	NavigationSplitView {
		List {
			NavigationLink {
				PasswordRules()
			} label: {
				Text("PasswordRules")
			}
		}
	} content: {
		PasswordRules()
	} detail: {
		EmptyView()
	}
}

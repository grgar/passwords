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
			#if os(watchOS)
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
				#if os(watchOS)
				Toggle("Favicon", isOn: $showFavicon)
				#else
				Picker("Favicon", selection: $showFavicon) {
					Label("Show", systemImage: "checklist.unchecked").tag(true)
					Label("Hide", systemImage: "list.bullet").tag(false)
				}
				.pickerStyle(.segmented)
				#endif
			}
			#if os(iOS)
			.sharedBackgroundVisibility(.hidden)
			#endif
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

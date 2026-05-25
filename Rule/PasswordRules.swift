import SwiftUI
import SwiftData

struct PasswordRules: View {
	struct IngestRule: Codable {
		let rule: String

		enum CodingKeys: String, CodingKey {
			case rule = "password-rules"
		}
	}

	@Query(sort: \PasswordRule.domain) private var cachedRules: [PasswordRule]
	@Environment(\.modelContext) private var modelContext

	@State var error: DecodingError?

	@State var searchText = ""

	@State var showHelp = false

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/password-rules.json")!

	private var rules: [Rule] {
		cachedRules.map { Rule(domain: $0.domain, rule: $0.ruleString) }
	}

	@MainActor
	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			let serverDomains = Set(data.keys)
			for (domain, ingestRule) in data {
				modelContext.insert(PasswordRule(domain: domain, ruleString: ingestRule.rule))
			}
			for cached in cachedRules where !serverDomains.contains(cached.domain) {
				modelContext.delete(cached)
			}
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
		let responses = rules
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
			guard cachedRules.isEmpty else { return }
			await reload()
		}
		.navigationTitle(Text("Password Rules"))
		#if os(iOS)
			.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

struct SamplePasswordRules: PreviewModifier {
	@MainActor static func makeSharedContext() throws -> ModelContainer {
		let container = try ModelContainer(
			for: PasswordRule.self,
			configurations: ModelConfiguration(isStoredInMemoryOnly: true)
		)
		container.mainContext.insert(PasswordRule(domain: "example.com", ruleString: "maxlength: 5;"))
		return container
	}

	func body(content: Content, context: ModelContainer) -> some View {
		content.modelContainer(context)
	}
}

extension PreviewTrait where T == Preview.ViewTraits {
	static var samplePasswordRules: Self = .modifier(SamplePasswordRules())
}

#Preview("Local", traits: .samplePasswordRules) {
	NavigationStack {
		PasswordRules()
	}
}

#Preview("Remote") {
	NavigationStack {
		PasswordRules()
	}
	.modelContainer(for: PasswordRule.self, inMemory: true)
}

#Preview("Table", traits: .fixedLayout(width: 960, height: 640), .samplePasswordRules) {
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

#Preview("Error", traits: .samplePasswordRules) {
	NavigationStack {
		PasswordRules(error: DecodingError.typeMismatch(String.self, .init(codingPath: [], debugDescription: "")))
	}
}

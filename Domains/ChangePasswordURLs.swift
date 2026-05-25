import SwiftUI
import SwiftData

struct ChangePasswordURLs: View {
	@Query(sort: \ChangePasswordURL.domain) private var cachedURLs: [ChangePasswordURL]
	@Environment(\.modelContext) private var modelContext

	@State var error: Error?

	@State var searchText = ""

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/change-password-URLs.json")!

	@AppStorage("showFavicon") private var showFavicon = true

	private var urlPairs: [(key: String, value: URL)] {
		cachedURLs.compactMap { cached in
			URL(string: cached.urlString).map { url in (key: cached.domain, value: url) }
		}
	}

	@MainActor
	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			let serverDomains = Set(data.keys)
			for (domain, url) in data {
				modelContext.insert(ChangePasswordURL(domain: domain, urlString: url.absoluteString))
			}
			for cached in cachedURLs where !serverDomains.contains(cached.domain) {
				modelContext.delete(cached)
			}
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<[String: URL], Error> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: getURL, cachePolicy: cache))
			let data = try JSONDecoder().decode([String: URL].self, from: response)
			return .success(data)
		} catch {
			return .failure(error)
		}
	}

	var body: some View {
		let responses = urlPairs
			.filter { searchText == "" || $0.key.localizedCaseInsensitiveContains(searchText) }

		List {
			if let error {
				Section("Error") {
					Label {
						Text(error.localizedDescription)
					} icon: {
						Image(systemName: "exclamationmark.triangle")
							.symbolRenderingMode(.hierarchical)
							.foregroundStyle(.red)
					}
				}
			}
			ForEach(responses, id: \.key) { response in
				#if os(watchOS)
				Label {
					LabeledContent {
						EmptyView()
					} label: {
						Text(response.key)
						Text(response.value.relativePath)
							.foregroundStyle(.secondary)
					}
				} icon: {
					if showFavicon {
						Favicon(domain: response.key)
					}
				}
				#else
				Link(destination: response.value) {
					Label {
						LabeledContent {
							Image(systemName: "arrow.up.forward.square")
								.foregroundStyle(.blue)
								.symbolRenderingMode(.hierarchical)
								.accessibilityHidden(true)
						} label: {
							Text(response.key)
							Text(response.value.relativePath)
								.foregroundStyle(.secondary)
						}
					} icon: {
						if showFavicon {
							Favicon(domain: response.key)
						}
					}
				}
				.foregroundStyle(.foreground)
				#endif
			}
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
		.searchSuggestions {
			if !searchText.contains(".") {
				ForEach(responses, id: \.key) { response in
					Text(response.key)
						.searchCompletion(response.key)
				}
			}
		}
		.refreshable {
			await reload()
		}
		.task {
			guard cachedURLs.isEmpty else { return }
			await reload()
		}
		.navigationTitle(Text("Change Password"))
		#if os(iOS)
			.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

@MainActor
private func makeChangePasswordURLsPreviewContainer(populate: (ModelContext) -> Void = { _ in }) -> ModelContainer {
	let container = try! ModelContainer(
		for: ChangePasswordURL.self,
		configurations: ModelConfiguration(isStoredInMemoryOnly: true)
	)
	populate(container.mainContext)
	return container
}

#Preview("Local") {
	ChangePasswordURLs()
		.modelContainer(makeChangePasswordURLsPreviewContainer {
			$0.insert(ChangePasswordURL(
				domain: "example.com",
				urlString: "https://example.com/.well-known/change-password"
			))
		})
}

#Preview("Remote") {
	NavigationStack {
		ChangePasswordURLs()
	}
	.modelContainer(makeChangePasswordURLsPreviewContainer())
}

#Preview("Error") {
	ChangePasswordURLs(error: URLError(URLError.notConnectedToInternet))
		.modelContainer(makeChangePasswordURLsPreviewContainer {
			$0.insert(ChangePasswordURL(
				domain: "example.com",
				urlString: "https://example.com/.well-known/change-password"
			))
		})
}

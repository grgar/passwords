import SwiftUI

struct ChangePasswordURLs: View {
	@State var response: [String: URL] = [:]
	@State var error: Error?

	@State var searchText = ""

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/change-password-URLs.json")!

	@AppStorage("showFavicon") private var showFavicon = true

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			response = data
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
		let responses = response
			.sorted { $0.key.lexicographicallyPrecedes($1.key) }
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
			guard response.isEmpty else { return }
			await reload(cache: .returnCacheDataElseLoad)
		}
		.navigationTitle(Text("Change Password"))
		#if os(iOS)
			.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Local") {
	ChangePasswordURLs(response: ["example.com": URL(string: "https://example.com/.well-known/change-password")!])
}

#Preview("Remote") {
	NavigationStack {
		ChangePasswordURLs()
	}
}

#Preview("Error") {
	ChangePasswordURLs(response: ["example.com": URL(string: "https://example.com/.well-known/change-password")!],
	                   error: URLError(URLError.notConnectedToInternet))
}

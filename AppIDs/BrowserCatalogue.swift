import SwiftUI

struct BrowserCatalogue: View {
	struct WebBrowser: Identifiable, Decodable {
		let longName: String
		let shortName: String
		let supportedPlatforms: [String]
		let platformSpecificInformation: [String: PlatformInfo]
		let supportedStoreIdentifiers: [Int]

		var id: String { longName }

		enum CodingKeys: String, CodingKey {
			case longName = "long_name"
			case shortName = "short_name"
			case supportedPlatforms = "supported_platforms"
			case platformSpecificInformation = "platform_specific_information"
			case supportedStoreIdentifiers = "supported_store_identifiers"
		}

		struct PlatformInfo: Decodable {
			let bundleIdentifier: String?
			let codeSigningIdentifier: String?
			let codeSigningTeamIdentifier: String?
			let extensionsInstallPath: String?
			let nativeMessagingBundleIdentifier: String?
			let nativeMessagingCodeSigningIdentifier: String?

			enum CodingKeys: String, CodingKey {
				case bundleIdentifier = "bundle_identifier"
				case codeSigningIdentifier = "code_signing_identifier"
				case codeSigningTeamIdentifier = "code_signing_team_identifier"
				case extensionsInstallPath = "extensions_install_path_relative_to_user_library_directory"
				case nativeMessagingBundleIdentifier = "extension_native_messaging_process_bundle_identifier"
				case nativeMessagingCodeSigningIdentifier = "extension_native_messaging_process_code_signing_identifier"
			}
		}
	}

	struct ExtensionStorefront: Identifiable, Decodable {
		let name: String
		let url: URL
		let identifier: Int
		var id: Int { identifier }
	}

	enum SearchToken: Identifiable, Hashable {
		case platform(String)
		case storefront(name: String, identifier: Int)

		var id: String {
			switch self {
			case .platform(let name): "platform:\(name)"
			case .storefront(_, let identifier): "storefront:\(identifier)"
			}
		}

		var label: String {
			switch self {
			case .platform(let name): name
			case .storefront(let name, _): name
			}
		}
	}

	struct Response: Decodable {
		let extensionStorefronts: [ExtensionStorefront]
		let webBrowsers: [WebBrowser]

		enum CodingKeys: String, CodingKey {
			case extensionStorefronts = "extension_storefronts"
			case webBrowsers = "web_browsers"
		}
	}

	@State var browsers: [WebBrowser] = []
	@State var storefronts: [ExtensionStorefront] = []
	@State var error: Error?

	@State var searchText = ""
	@State var searchTokens: [SearchToken] = []

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/web-browser-extension-distribution-information.json")!

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			browsers = data.webBrowsers
			storefronts = data.extensionStorefronts
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	func silentReload() async {
		switch await Self.reload(cache: .reloadIgnoringLocalCacheData) {
		case let .success(data):
			withAnimation {
				browsers = data.webBrowsers
				storefronts = data.extensionStorefronts
				error = nil
			}
		case .failure:
			break
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<Response, Error> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: getURL, cachePolicy: cache))
			let data = try JSONDecoder().decode(Response.self, from: response)
			return .success(data)
		} catch {
			return .failure(error)
		}
	}

	var suggestedSearchTokens: [SearchToken] {
		let selectedPlatforms = Set(searchTokens.compactMap { if case .platform(let name) = $0 { name } else { nil } })
		let selectedStorefronts = Set(searchTokens.compactMap { if case .storefront(_, let id) = $0 { id } else { nil } })
		let platformTokens = Array(Set(browsers.flatMap(\.supportedPlatforms)))
			.filter { !selectedPlatforms.contains($0) }
			.sorted()
			.map { SearchToken.platform($0) }
		let storefrontTokens = storefronts
			.filter { !selectedStorefronts.contains($0.identifier) }
			.map { SearchToken.storefront(name: $0.name, identifier: $0.identifier) }
		return platformTokens + storefrontTokens
	}

	var filteredBrowsers: [WebBrowser] {
		browsers.filter { browser in
			(searchText.isEmpty ||
			browser.longName.localizedCaseInsensitiveContains(searchText) ||
			browser.shortName.localizedCaseInsensitiveContains(searchText)) &&
			searchTokens.allSatisfy { token in
				switch token {
				case .platform(let name): browser.supportedPlatforms.contains(name)
				case .storefront(_, let id): browser.supportedStoreIdentifiers.contains(id)
				}
			}
		}
	}

	@State private var showFavicon = true

	var body: some View {
		List {
			if !storefronts.isEmpty, searchText.isEmpty, searchTokens.isEmpty {
				Section {
					ForEach(storefronts) { storefront in
						Link(destination: storefront.url) {
							Label {
								LabeledContent {
									Image(systemName: "arrow.up.forward.square")
										.foregroundStyle(.blue)
										.symbolRenderingMode(.hierarchical)
										.accessibilityHidden(true)
								} label: {
									Text(storefront.name)
									if let host = storefront.url.host(percentEncoded: false) {
										Text(host)
											.foregroundStyle(.secondary)
									}
								}
							} icon: {
								if showFavicon, let host = storefront.url.host() {
									Favicon(domain: host)
								}
							}
						}
						.foregroundStyle(.foreground)
					}
				} header: {
					Text("Extension Storefronts")
						.textCase(nil)
						.font(.caption)
				} footer: {
					Text("iCloud Keychain is available from these browser extension stores.")
				}
			}

			Section {
				ForEach(filteredBrowsers) { browser in
					VStack(alignment: .leading, spacing: 4) {
						Text(browser.longName)
						if let macInfo = browser.platformSpecificInformation["Mac"],
						   let bundleID = macInfo.bundleIdentifier {
							Text(bundleID)
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						HStack(spacing: 4) {
							ForEach(browser.supportedPlatforms, id: \.self) { platform in
								Text(platform)
									.font(.caption2)
									.padding(.horizontal, 7)
									.padding(.vertical, 2)
									.background(.secondary.opacity(0.15), in: Capsule())
							}
						}
						.foregroundStyle(.secondary)
					}
					.multilineTextAlignment(.leading)
				}
			} header: {
				Text("Web Browsers")
			} footer: {
				Text("iCloud Keychain is allowed to communicate and share your passwords with these web browsers.")
			}
		}
		#if os(watchOS)
		.searchable(text: $searchText, prompt: Text("Search Browsers"))
		#else
		.searchable(text: $searchText, tokens: $searchTokens, suggestedTokens: .constant(suggestedSearchTokens), prompt: Text("Search Browsers")) { token in
				Text(token.label)
			}
		#endif
		.refreshable {
			await reload()
		}
		.task {
			guard browsers.isEmpty else { return }
			await reload(cache: .returnCacheDataElseLoad)
			guard URLCache.shared.isStale(for: Self.getURL) else { return }
			await silentReload()
		}
		.navigationTitle(Text("Browser Catalogue"))
		#if os(iOS)
		.listStyle(.inset)
		.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Local") {
	NavigationStack {
		BrowserCatalogue(
			browsers: [
				.init(
					longName: "Google Chrome", shortName: "Chrome",
					supportedPlatforms: ["Mac", "Windows", "Linux"],
					platformSpecificInformation: ["Mac": .init(
						bundleIdentifier: "com.google.Chrome",
						codeSigningIdentifier: "com.google.Chrome",
						codeSigningTeamIdentifier: "EQHXZ8M8AV",
						extensionsInstallPath: "Application Support/Google/Chrome/Default/Extensions",
						nativeMessagingBundleIdentifier: nil,
						nativeMessagingCodeSigningIdentifier: nil
					)],
					supportedStoreIdentifiers: [1]
				),
				.init(
					longName: "Mozilla Firefox", shortName: "Firefox",
					supportedPlatforms: ["Mac", "Windows", "Linux"],
					platformSpecificInformation: [:],
					supportedStoreIdentifiers: [3]
				),
			],
			storefronts: [
				.init(name: "Chrome Web Store", url: URL(string: "https://chromewebstore.google.com/category/extensions")!, identifier: 1),
				.init(name: "Firefox Browser Add-ons", url: URL(string: "https://addons.mozilla.org")!, identifier: 3),
			]
		)
	}
}

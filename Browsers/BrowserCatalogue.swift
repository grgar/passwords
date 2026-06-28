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

	var filteredBrowsers: [WebBrowser] {
		browsers.filter {
			searchText.isEmpty ||
			$0.longName.localizedCaseInsensitiveContains(searchText) ||
			$0.shortName.localizedCaseInsensitiveContains(searchText)
		}
	}

	var body: some View {
		List {
			if !storefronts.isEmpty {
				Section {
					ForEach(storefronts) { storefront in
						Link(destination: storefront.url) {
							Label(storefront.name, systemImage: "storefront")
						}
					}
				} header: {
					Text("Extension Storefronts")
						.textCase(nil)
						.font(.caption)
				} footer: {
					Text("Stores from which password manager browser extensions can be distributed.")
				}
			}

			Section {
				ForEach(filteredBrowsers) { browser in
					VStack(alignment: .leading, spacing: 2) {
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
									.padding(.horizontal, 5)
									.padding(.vertical, 2)
									.background(.secondary.opacity(0.15), in: Capsule())
							}
						}
						.foregroundStyle(.secondary)
					}
					.multilineTextAlignment(.leading)
				}
			} header: {} footer: {
				Text("Web browsers with bundle IDs, code-signing information, platform support, and extension store links.")
			}
		}
		.searchable(text: $searchText, prompt: Text("Search Browsers"))
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

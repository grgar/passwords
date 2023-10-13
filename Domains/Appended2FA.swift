import SwiftUI

struct Appended2FA: View {
	@State var response: [String] = []
	@State var error: Error?

	@State var searchText = ""

	@State var showHelp = false

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/websites-that-append-2fa-to-password.json")!

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			response = data
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<[String], Error> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: getURL, cachePolicy: cache))
			let data = try JSONDecoder().decode([String].self, from: response)
			return .success(data)
		} catch {
			return .failure(error)
		}
	}

	var body: some View {
		let responses = response
			.filter { searchText == "" || $0.localizedCaseInsensitiveContains(searchText) }

		GeometryReader { geometry in
			List {
				Section {
					ForEach(responses, id: \.hashValue) { response in
						Text(response)
					}
				} header: {} footer: {
					Text("Domains which use a two-factor authentication scheme where you must append a generated code to your password when signing in.")
				}
			}
			#if os(iOS)
			.toolbar {
				Button {
					showHelp.toggle()
				} label: {
					Label("Help", systemImage: "questionmark.circle")
						.symbolVariant(showHelp ? .fill : .none)
				}
				.popover(isPresented: $showHelp, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
					List {
						Section {
							Text("prevent auto-submission of signin forms, allowing you to append the 2FA code without frustration")
							Text("suppress prompting to update a saved password when the submitted password is prefixed by the already-stored password")
						} header: {
							Text("This list of websites is used to")
								.textCase(nil)
								.font(.body)
						}
					}
					.listStyle(.inset)
					.frame(minWidth: geometry.size.width / 2, minHeight: geometry.size.width < geometry.size.height ? 0 : geometry.size.height / 3 * 2)
					.presentationDragIndicator(.visible)
					.presentationDetents([.fraction(0.3), .medium])
					.presentationBackgroundInteraction(.enabled)
					.presentationCompactAdaptation(horizontal: .sheet, vertical: .popover)
				}
			}
			#endif
		}
		.searchable(text: $searchText, prompt: Text("Search Domains"))
		.refreshable {
			await reload()
		}
		.task {
			guard response.isEmpty else { return }
			await reload(cache: .returnCacheDataElseLoad)
		}
		.navigationTitle(Text("Appended 2FA"))
		#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Local") {
	NavigationStack {
		Appended2FA(response: ["a.com", "b.com"])
	}
}

#Preview("Help") {
	NavigationStack {
		Appended2FA(response: ["a.com"], showHelp: true)
	}
}

import SwiftUI
import SwiftData

struct Appended2FAs: View {
	@Query(sort: \Appended2FA.domain) private var cachedDomains: [Appended2FA]
	@Environment(\.modelContext) private var modelContext

	@State var error: Error?

	@State var searchText = ""

	@State var showHelp = false

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/websites-that-append-2fa-to-password.json")!

	private var domains: [String] { cachedDomains.map(\.domain) }

	@MainActor
	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			let serverDomains = Set(data)
			for domain in data {
				modelContext.insert(Appended2FA(domain: domain))
			}
			for cached in cachedDomains where !serverDomains.contains(cached.domain) {
				modelContext.delete(cached)
			}
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
		let responses = domains
			.filter { searchText == "" || $0.localizedCaseInsensitiveContains(searchText) }

		List {
			Section {
				Text("prevent auto-submission of signin forms, allowing you to append the 2FA code without frustration")
				Text("suppress prompting to update a saved password when the submitted password is prefixed by the already-stored password")
			} header: {
				Text("This list of websites is used to")
					.textCase(nil)
					.font(.caption)
			}
			.font(.caption)

			Section {
				ForEach(responses, id: \.hashValue) { response in
					Text(response)
				}
			} header: {} footer: {
				Text("Domains which use a two-factor authentication scheme where you must append a generated code to your password when signing in.")
			}
		}
		.searchable(text: $searchText, prompt: Text("Search Domains"))
		.refreshable {
			await reload()
		}
		.task {
			guard cachedDomains.isEmpty else { return }
			await reload()
		}
		.navigationTitle(Text("Appended 2FA"))
		#if os(iOS)
			.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

struct SampleAppended2FAs: PreviewModifier {
	@MainActor static func makeSharedContext() throws -> ModelContainer {
		let container = try ModelContainer(
			for: Appended2FA.self,
			configurations: ModelConfiguration(isStoredInMemoryOnly: true)
		)
		container.mainContext.insert(Appended2FA(domain: "a.com"))
		container.mainContext.insert(Appended2FA(domain: "b.com"))
		return container
	}

	func body(content: Content, context: ModelContainer) -> some View {
		content.modelContainer(context)
	}
}

extension PreviewTrait where T == Preview.ViewTraits {
	static var sampleAppended2FAs: Self = .modifier(SampleAppended2FAs())
}

#Preview("Local", traits: .sampleAppended2FAs) {
	NavigationStack {
		Appended2FAs()
	}
}

#Preview("Help", traits: .sampleAppended2FAs) {
	NavigationStack {
		Appended2FAs(showHelp: true)
	}
}

import SwiftUI
import SwiftData

struct SharedCredentials: View {
	struct Entry: Codable, Hashable {
		var shared: [String]?
		var from: [String]?
		var to: [String]?
		var fromDomainsAreObsoleted: Bool?
	}

	@Query private var cachedCredentials: [SharedCredential]
	@Environment(\.modelContext) private var modelContext

	@State var error: Error?

	@State var searchText = ""

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/shared-credentials.json")!

	private var entries: [Entry] {
		cachedCredentials.map {
			Entry(
				shared: $0.shared.isEmpty ? nil : $0.shared,
				from: $0.from.isEmpty ? nil : $0.from,
				to: $0.to.isEmpty ? nil : $0.to,
				fromDomainsAreObsoleted: $0.fromDomainsAreObsoleted
			)
		}
	}

	@MainActor
	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			let serverIDs = Set(data.map {
				SharedCredential.makeID(shared: $0.shared, from: $0.from, to: $0.to)
			})
			for entry in data {
				modelContext.insert(SharedCredential(
					shared: entry.shared ?? [],
					from: entry.from ?? [],
					to: entry.to ?? [],
					fromDomainsAreObsoleted: entry.fromDomainsAreObsoleted ?? false
				))
			}
			for cached in cachedCredentials where !serverIDs.contains(cached.entryID) {
				modelContext.delete(cached)
			}
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	static func reload(cache: NSURLRequest.CachePolicy) async -> Result<[Entry], Error> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: getURL, cachePolicy: cache))
			let data = try JSONDecoder().decode([Entry].self, from: response)
			return .success(data)
		} catch {
			return .failure(error)
		}
	}

	var body: some View {
		let responses = entries
			.filter { searchText == "" || (($0.shared ?? []) + ($0.from ?? []) + ($0.to ?? [])).joined(separator: "§").localizedCaseInsensitiveContains(searchText) }

		List {
			Section {
				ForEach(responses.filter { $0.shared != nil }, id: \.hashValue) { response in
					if let shared = response.shared {
						VStack(alignment: .leading) {
							ForEach(shared, id: \.self) { shared in
								Text(shared)
							}
						}
						.multilineTextAlignment(.leading)
					}
				}
			} header: {
				Text("Shared")
			} footer: {
				Text("Domains whose credentials are all shared.")
			}

			Section {
				ForEach(responses.filter { $0.from != nil && $0.to != nil }, id: \.hashValue) { response in
					if let from = response.from, let to = response.to {
						LabeledContent {
							VStack(alignment: .trailing) {
								ForEach(from, id: \.self) { from in
									Text(from)
										.strikethrough(response.fromDomainsAreObsoleted ?? false)
								}
							}
							.multilineTextAlignment(.trailing)
						} label: {
							VStack(alignment: .leading) {
								ForEach(to, id: \.self) { to in
									Text(to)
								}
							}
							.multilineTextAlignment(.leading)
						}
					}
				}
			} header: {
				VStack(alignment: .leading) {
					Text("Transitioned")
					HStack {
						Text("New")
						Spacer()
						Text("Old")
					}
					.textCase(nil)
				}
			} footer: {
				Text("Credentials to be shared one-way.")
			}
		}
		.searchable(text: $searchText, prompt: Text("Search Domains"))
		.refreshable {
			await reload()
		}
		.task {
			guard cachedCredentials.isEmpty else { return }
			await reload()
		}
		.navigationTitle(Text("Shared Credentials"))
		#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

struct SampleSharedCredentials: PreviewModifier {
	@MainActor static func makeSharedContext() throws -> ModelContainer {
		let container = try ModelContainer(
			for: SharedCredential.self,
			configurations: ModelConfiguration(isStoredInMemoryOnly: true)
		)
		let context = container.mainContext
		context.insert(SharedCredential(shared: ["example.com"]))
		context.insert(SharedCredential(from: ["a.com"], to: ["b.com"]))
		context.insert(SharedCredential(from: ["a.com"], to: ["b.com"], fromDomainsAreObsoleted: true))
		context.insert(SharedCredential(from: ["a.com", "b.com"], to: ["c.com"], fromDomainsAreObsoleted: true))
		context.insert(SharedCredential(from: ["a.com", "b.com"], to: ["c.com", "d.com"], fromDomainsAreObsoleted: true))
		context.insert(SharedCredential(from: ["a.com"], to: ["c.com", "d.com"], fromDomainsAreObsoleted: true))
		context.insert(SharedCredential(shared: ["a.com", "b.com", "c.com", "d.com"]))
		return container
	}

	func body(content: Content, context: ModelContainer) -> some View {
		content.modelContainer(context)
	}
}

extension PreviewTrait where T == Preview.ViewTraits {
	static var sampleSharedCredentials: Self = .modifier(SampleSharedCredentials())
}

#Preview("Local", traits: .sampleSharedCredentials) {
	NavigationStack {
		SharedCredentials()
	}
}

import SwiftUI

struct ChangePasswordURLs: View {
	@State var response: [String: URL] = [:]
	@State var error: Error?

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(cache: cache) {
		case let .success(data):
			response = data
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	static let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/change-password-URLs.json")!

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
			ForEach(response.sorted(by: { $0.key.lexicographicallyPrecedes($1.key) }), id: \.key) { response in
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
						.alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] }
					} icon: {
						AsyncImage(url: URL(string: "https://\(response.key)/favicon.ico")) { phase in
							if let image = phase.image {
								image
									.resizable()
									.scaledToFit()
							} else if let error = phase.error {
								Image(systemName: "ellipsis.circle")
									.resizable()
									.scaledToFit()
									.opacity(0)
									.accessibilityHidden(true)
							} else {
								Image(systemName: "ellipsis.circle")
									.resizable()
									.scaledToFit()
									.redacted(reason: .placeholder)
									.accessibilityHidden(true)
							}
						}
						.alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] }
					}
				}
				.foregroundStyle(.foreground)
			}
		}
		.refreshable {
			await reload()
		}
		.task {
			guard response.isEmpty else { return }
			await reload()
		}
	}
}

#Preview("Local") {
	ChangePasswordURLs(response: ["example.com": URL(string: "https://example.com/.well-known/change-password")!])
}

#Preview("Remote") {
	ChangePasswordURLs()
}

#Preview("Error") {
	ChangePasswordURLs(response: ["example.com": URL(string: "https://example.com/.well-known/change-password")!],
	                   error: URLError(URLError.notConnectedToInternet))
}

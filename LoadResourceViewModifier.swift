import SwiftUI

struct LoadResourceViewModifier<Response: Decodable, Output: Equatable & RandomAccessCollection>: ViewModifier {
	@State var response: Output
	
	@State var error: DecodingError?
	@State var searchText = ""

	let getURL = URL(string: "https://raw.githubusercontent.com/apple/password-manager-resources/main/quirks/password-rules.json")!
	let transformer: (Response) -> Output

	func reload(cache: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async {
		switch await Self.reload(fromURL: getURL, cache: cache) {
		case let .success(data):
			response = transformer(data)
			error = nil
		case let .failure(error):
			self.error = error
		}
	}

	static func reload(fromURL url: URL, cache: NSURLRequest.CachePolicy) async -> Result<Response, DecodingError> {
		do {
			let (response, _) = try await URLSession.shared.data(for: URLRequest(url: url, cachePolicy: cache))
			let data = try JSONDecoder().decode(Response.self, from: response)
			return .success(data)
		} catch {
			if let error = error as? DecodingError {
				return .failure(error)
			}
			return .failure(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unknown error", underlyingError: error)))
		}
	}

	func body(content: Content) -> some View {
		let isError = Binding(get: {
			error != nil
		}, set: {
			if !$0 {
				error = nil
			}
		})

		content
			.searchable(text: $searchText, prompt: Text("Search"))
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
	}
}

extension View {
	func loadResource<Response: Decodable, Output: Equatable & RandomAccessCollection>(
		initial: Output,
		transformer: @escaping (Response) -> Output
	) -> some View {
		modifier(LoadResourceViewModifier(response: initial, transformer: transformer))
	}
}

struct RefreshButton: View {
	@Binding var isError: Bool

	@Environment(\.refresh) private var refresh

	var body: some View {
		Button {
			isError = false
			Task {
				await refresh?()
			}
		} label: {
			Text("Retry")
		}
	}
}

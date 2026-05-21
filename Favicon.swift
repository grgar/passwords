import SwiftUI

struct Favicon: View {
	let domain: String

	@AppStorage("useGoogleFaviconAPI") private var useGoogleFaviconAPI = true

	private var faviconURL: URL? {
		if useGoogleFaviconAPI {
			URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=32")
		} else {
			URL(string: "https://\(domain)/favicon.ico")
		}
	}

	var body: some View {
		AsyncImage(url: faviconURL) { phase in
			if let image = phase.image {
				image
					.resizable()
			} else if phase.error != nil {
				Image(systemName: "questionmark.circle.dashed")
					.resizable()
					.foregroundStyle(.secondary)
			} else {
				#if os(macOS)
				Image(systemName: "questionmark.circle.dashed")
					.resizable()
					.foregroundStyle(.clear)
					.overlay {
						ProgressView()
							.controlSize(.small)
					}
				#else
				ProgressView()
				#endif
			}
		}
		.scaledToFit()
		.accessibilityHidden(true)
	}
}

#Preview {
	Favicon(domain: "apple.com")
	Favicon(domain: "127.0.0.1")
}

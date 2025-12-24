import SwiftUI

struct Favicon: View {
	let domain: String
	
	var body: some View {
		AsyncImage(url: URL(string: "https://\(domain)/favicon.ico")) { phase in
			if let image = phase.image {
				image
					.resizable()
			} else if phase.error != nil {
				Image(systemName: "questionmark.circle.dashed")
					.resizable()
					.foregroundStyle(.secondary)
			} else {
				ProgressView()
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

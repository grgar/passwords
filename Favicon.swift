import SwiftUI

struct Favicon: View {
	let domain: String

	var body: some View {
		AsyncImage(url: URL(string: "https://\(domain)/favicon.ico")) { phase in
			if let image = phase.image {
				image
					.resizable()
					.scaledToFit()
			} else if phase.error != nil {
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
	}
}

#Preview {
	Favicon(domain: "apple.com")
}

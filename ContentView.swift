import SwiftUI

enum NavigationCategory: View {
	case rules, shared, change, appended

	var body: some View {
		switch self {
		case .rules:
			PasswordRules()
		case .shared:
			SharedCredentials()
		case .change:
			ChangePasswordURLs()
		case .appended:
			Appended2FA()
		}
	}
}

struct ContentView: View {
	@State private var visibility: NavigationSplitViewVisibility = .all

	@State private var navigationCategory: NavigationCategory?

	var body: some View {
		NavigationSplitView(columnVisibility: $visibility) {
			HomeSidebar(selection: $navigationCategory)
				.listStyle(.sidebar)
		} content: {
			if let navigationCategory {
				navigationCategory
					.navigationSplitViewColumnWidth(min: 320, ideal: 640)
			}
		} detail: {
			Text("")
				.accessibilityHidden(true)
				.navigationSplitViewColumnWidth(ideal: navigationCategory == .rules ? 320 : 0,
																				max: navigationCategory == .rules ? 480 : 0)
		}
	}
}

#if os(macOS)
#Preview(traits: .fixedLayout(width: 960, height: 640)) {
	ContentView()
}
#else
#Preview {
	ContentView()
}
#endif

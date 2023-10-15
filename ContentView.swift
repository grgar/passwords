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
		#if os(tvOS)
		NavigationStack {
			PasswordRules()
				.background {
					HomeBackground()
				}
		}
		#else
		NavigationSplitView(columnVisibility: $visibility) {
			HomeSidebar(selection: $navigationCategory)
			#if os(iOS) || os(macOS)
				.listStyle(.sidebar)
			#endif
		} content: {
			if let navigationCategory {
				navigationCategory
					.navigationSplitViewColumnWidth(min: 320, ideal: 640)
			}
		} detail: {
			Text("")
				.accessibilityHidden(true)
				.navigationSplitViewColumnWidth(min: navigationCategory == .rules ? 320 : 0,
				                                ideal: navigationCategory == .rules ? 320 : 0,
				                                max: navigationCategory == .rules ? 480 : 0)
		}
		#if os(macOS)
		.frame(minWidth: 320 + 320 + (navigationCategory == .rules ? 320 : 0))
		#endif
		#endif
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

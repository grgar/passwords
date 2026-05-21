import SwiftUI

struct ContentView: View {
	@State private var visibility: NavigationSplitViewVisibility = .all

	@SceneStorage("navigationCategory") private var navigationCategoryRaw: String?

	private var navigationCategory: NavigationCategory? {
		navigationCategoryRaw.flatMap(NavigationCategory.init)
	}

	private var navigationCategoryBinding: Binding<NavigationCategory?> {
		Binding(
			get: { navigationCategoryRaw.flatMap(NavigationCategory.init) },
			set: { navigationCategoryRaw = $0?.rawValue }
		)
	}

	var body: some View {
		NavigationSplitView(columnVisibility: $visibility) {
			HomeSidebar(selection: navigationCategoryBinding)
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
	}
}

#Preview {
	ContentView()
}

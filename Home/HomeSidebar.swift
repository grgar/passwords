import SwiftUI

struct HomeSidebar: View {
	@Binding var selection: NavigationCategory?

	var body: some View {
		List(selection: $selection) {
			ForEach(NavigationCategory.allCases, id: \.self) { category in
				NavigationLink(value: category) {
					NavigationCategory.LinkLabel(category: category)
				}
			}
		}
		#if os(iOS) || os(macOS)
		.scrollContentBackground(.hidden)
		.listStyle(.sidebar)
		#endif
		.background {
			HomeBackground()
		}
		.navigationTitle(Text("Passwords Inspector"))
		#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
		#else
			.navigationSplitViewColumnWidth(min: 180, ideal: 180)
		#endif
			.toolbar {
				#if os(iOS)
				ToolbarItemGroup(placement: .principal) {
					Label {
						Text("Passwords Inspector")
					} icon: {
						Image(systemName: "key.fill")
							.rotationEffect(.radians(-0.3))
					}
					.labelStyle(.titleAndIcon)
					.foregroundStyle(.tint, .tertiary)
				}
				#endif
			}
	}
}

#Preview {
	NavigationStack {
		HomeSidebar(selection: .constant(nil))
	}
}

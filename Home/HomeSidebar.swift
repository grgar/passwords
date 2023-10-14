import SwiftUI

struct HomeSidebar: View {
	@Binding var selection: NavigationCategory?

	var body: some View {
		List(selection: $selection) {
			NavigationLink(value: NavigationCategory.rules) {
				Label {
					#if os(iOS)
					LabeledContent {
						EmptyView()
					} label: {
						Text("Password Rules")
						Text("Rules to generate compatible passwords with websites' particular requirements.")
					}
					#else
					Text("Password Rules")
					#if os(tvOS)
						.padding(.horizontal, 96)
					#endif
					#endif
				} icon: {
					Image(systemName: "lock.rectangle")
					#if os(tvOS)
						.font(.largeTitle)
						.padding(.leading, 64)
					#endif
				}
				#if os(iOS)
				.padding(.vertical)
				#endif
			}

			NavigationLink(value: NavigationCategory.shared) {
				Label {
					#if os(iOS)
					LabeledContent {
						EmptyView()
					} label: {
						Text("Shared Credentials")
						Text("Groups of websites known to use the same credential backend, which can be used to enhance suggested credentials to sign in to websites.")
					}
					#else
					Text("Shared Credentials")
					#if os(tvOS)
						.padding(.horizontal, 96)
					#endif
					#endif
				} icon: {
					Image(systemName: "rectangle.on.rectangle.angled")
					#if os(tvOS)
						.font(.largeTitle)
						.padding(.leading, 64)
					#endif
				}
				#if os(iOS)
				.padding(.vertical)
				#endif
			}

			NavigationLink(value: NavigationCategory.change) {
				Label {
					#if os(iOS)
					LabeledContent {
						EmptyView()
					} label: {
						Text("Change Password URLs")
						Text("To drive the adoption of strong passwords, it's useful to be able to take users directly to websites' change password pages.")
					}
					#else
					Text("Change Password URLs")
					#if os(tvOS)
						.padding(.horizontal, 96)
					#endif
					#endif
				} icon: {
					Image(systemName: "rectangle.and.pencil.and.ellipsis")
					#if os(tvOS)
						.font(.largeTitle)
						.padding(.leading, 64)
					#endif
				}
				#if os(iOS)
				.padding(.vertical)
				#endif
			}

			NavigationLink(value: NavigationCategory.appended) {
				Label {
					#if os(iOS)
					LabeledContent {
						EmptyView()
					} label: {
						Text("Websites Where 2FA Code is Appended to Password")
						Text("Some websites use a two-factor authentication scheme where the user must append a generated code to their password when signing in.")
					}
					#else
					Text("Appended 2FA")
					#if os(tvOS)
						.padding(.horizontal, 96)
					#endif
					#endif
				} icon: {
					Image(systemName: "123.rectangle")
					#if os(tvOS)
						.font(.largeTitle)
						.padding(.leading, 64)
					#endif
				}
				#if os(iOS)
				.padding(.vertical)
				#endif
			}
		}
		#if !os(tvOS)
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
	HomeSidebar(selection: .constant(nil))
}

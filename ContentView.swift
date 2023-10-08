import SwiftUI

struct ContentView: View {
	var body: some View {
		NavigationSplitView {
			List {
				NavigationLink {
					PasswordRules()
				} label: {
					Label {
						LabeledContent {
							EmptyView()
						} label: {
							Text("Password Rules")
							Text("Rules to generate compatible passwords with websites' particular requirements.")
						}
					} icon: {
						Image(systemName: "lock.rectangle")
					}
					.padding(.vertical)
				}

				NavigationLink {
					SharedCredentials()
				} label: {
					Label {
						LabeledContent {
							EmptyView()
						} label: {
							Text("Shared Credentials")
							Text("Groups of websites known to use the same credential backend, which can be used to enhance suggested credentials to sign in to websites.")
						}
					} icon: {
						Image(systemName: "rectangle.on.rectangle.angled")
					}
					.padding(.vertical)
				}

				NavigationLink {
					ChangePasswordURLs()
				} label: {
					Label {
						LabeledContent {
							EmptyView()
						} label: {
							Text("Change Password URLs")
							Text("To drive the adoption of strong passwords, it's useful to be able to take users directly to websites' change password pages.")
						}
					} icon: {
						Image(systemName: "rectangle.and.pencil.and.ellipsis")
					}
					.padding(.vertical)
				}

				NavigationLink {
					Appended2FA()
				} label: {
					Label {
						LabeledContent {
							EmptyView()
						} label: {
							Text("Websites Where 2FA Code is Appended to Password")
							Text("Some websites use a two-factor authentication scheme where the user must append a generated code to their password when signing in.")
						}
					} icon: {
						Image(systemName: "123.rectangle")
					}
					.padding(.vertical)
				}
			}
			.scrollContentBackground(.hidden)
			.background {
				HomeBackground()
			}
			.listStyle(.sidebar)
			.navigationTitle(Text("Passwords Inspector"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
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
			}
		} content: {
			EmptyView()
		} detail: {
			EmptyView()
		}
	}
}

#Preview {
	ContentView()
}

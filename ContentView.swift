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
				}
			}
			.listStyle(.sidebar)
		} detail: {
			EmptyView()
		}
	}
}

#Preview {
	ContentView()
}

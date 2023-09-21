import SwiftUI

struct ContentView: View {
	var body: some View {
		NavigationSplitView {
			List {
				NavigationLink {
					EmptyView()
				} label: {
					LabeledContent {
						EmptyView()
					} label: {
						Text("Password Rules")
						Text("Rules to generate compatible passwords with websites' particular requirements.")
					}
				}

				NavigationLink {
					EmptyView()
				} label: {
					LabeledContent {
						EmptyView()
					} label: {
						Text("Shared Credentials")
						Text("Groups of websites known to use the same credential backend, which can be used to enhance suggested credentials to sign in to websites.")
					}
				}

				NavigationLink {
					ChangePasswordURLs()
				} label: {
					LabeledContent {
						EmptyView()
					} label: {
						Text("Change Password URLs")
						Text("To drive the adoption of strong passwords, it's useful to be able to take users directly to websites' change password pages.")
					}
				}

				NavigationLink {
					EmptyView()
				} label: {
					LabeledContent {
						EmptyView()
					} label: {
						Text("Websites Where 2FA Code is Appended to Password")
						Text("Some websites use a two-factor authentication scheme where the user must append a generated code to their password when signing in.")
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

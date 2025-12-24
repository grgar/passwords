import SwiftUI

enum NavigationCategory: View, CaseIterable {
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

	struct LinkLabel: View {
		let category: NavigationCategory

		var body: some View {
			Label {
				#if os(iOS)
				LabeledContent {
					EmptyView()
				} label: {
					Text(category.title)
					Text(category.longSubtitle)
				}
				#else
				Text(category.title)
				#endif
			} icon: {
				Image(systemName: category.icon)
			}
		}
	}

	var title: String {
		switch self {
		case .rules:
			"Password Rules"
		case .shared:
			"Shared Credentials"
		case .change:
			"Change Password URLs"
		case .appended:
			"Appended 2FA"
		}
	}

	var longSubtitle: String {
		switch self {
		case .rules:
			"Rules to generate compatible passwords with websites' particular requirements."
		case .shared:
			"Groups of websites known to use the same credential backend, which can be used to enhance suggested credentials to sign in to websites."
		case .change:
			"To drive the adoption of strong passwords, it's useful to be able to take users directly to websites' change password pages."
		case .appended:
			"Some websites use a two-factor authentication scheme where the user must append a generated code to their password when signing in."
		}
	}

	var icon: String {
		switch self {
		case .rules:
			"lock.rectangle"
		case .shared:
			"rectangle.on.rectangle.angled"
		case .change:
			"rectangle.and.pencil.and.ellipsis"
		case .appended:
			"123.rectangle"
		}
	}
}

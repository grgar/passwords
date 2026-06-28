import SwiftUI

enum NavigationCategory: String, View, CaseIterable {
	case rules, shared, change, appended, embeddedThirdParty, appIDs, browsers

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
		case .embeddedThirdParty:
			EmbeddedThirdParty()
		case .appIDs:
			AppIDCredentials()
		case .browsers:
			BrowserCatalogue()
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
		case .embeddedThirdParty:
			"Embedded Third-Party"
		case .appIDs:
			"App ID Credentials"
		case .browsers:
			"Browser Catalogue"
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
		case .embeddedThirdParty:
			"Domains that, when embedded as a third party, ask for credentials belonging to a different service."
		case .appIDs:
			"Native apps and the websites they share credentials with, used for AutoFill suggestions on iOS 17.4 and later."
		case .browsers:
			"Web browsers with bundle IDs, code-signing information, platform support, and extension store links."
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
		case .embeddedThirdParty:
			"puzzlepiece.extension"
		case .appIDs:
			"apps.iphone"
		case .browsers:
			"globe"
		}
	}
}

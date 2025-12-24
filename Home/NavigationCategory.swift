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

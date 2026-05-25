import SwiftUI
import SwiftData

@main
struct PIApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.modelContainer(for: [
			PasswordRule.self,
			ChangePasswordURL.self,
			Appended2FA.self,
			SharedCredential.self,
		])
	}
}

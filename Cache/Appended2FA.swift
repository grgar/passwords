import SwiftData

@Model
final class Appended2FA {
	@Attribute(.unique) var domain: String

	init(domain: String) {
		self.domain = domain
	}
}

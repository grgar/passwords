import SwiftData

@Model
final class PasswordRule {
	@Attribute(.unique) var domain: String
	var ruleString: String

	init(domain: String, ruleString: String) {
		self.domain = domain
		self.ruleString = ruleString
	}
}

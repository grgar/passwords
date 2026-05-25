import SwiftData

@Model
final class ChangePasswordURL {
	@Attribute(.unique) var domain: String
	var urlString: String

	init(domain: String, urlString: String) {
		self.domain = domain
		self.urlString = urlString
	}
}

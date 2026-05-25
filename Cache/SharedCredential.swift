import SwiftData

@Model
final class SharedCredential {
	@Attribute(.unique) var entryID: String
	var shared: [String]
	var from: [String]
	var to: [String]
	var fromDomainsAreObsoleted: Bool

	init(shared: [String] = [], from: [String] = [], to: [String] = [], fromDomainsAreObsoleted: Bool = false) {
		self.entryID = Self.makeID(shared: shared, from: from, to: to)
		self.shared = shared
		self.from = from
		self.to = to
		self.fromDomainsAreObsoleted = fromDomainsAreObsoleted
	}

	static func makeID(shared: [String]?, from: [String]?, to: [String]?) -> String {
		((shared ?? []) + (from ?? []) + (to ?? [])).sorted().joined(separator: "|")
	}
}

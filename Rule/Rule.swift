import Foundation
import RegexBuilder

struct Rule: Identifiable {
	let id: String
	let originalRule: String

	var minLength: Int?
	var maxLength: Int?
	var required = Set<PasswordCharacter>()
	var allowed = Set<PasswordCharacter>()
	
	var sumLength: Int { (minLength ?? 0) + (maxLength ?? 0) }

	enum PasswordCharacter: LosslessStringConvertible, Hashable, CaseIterable, Comparable, Identifiable {
		case lower, upper, digit, special, unicode, other(Set<Character>)

		init?(_ description: String) {
			switch description {
			case "lower":
				self = .lower
			case "upper":
				self = .upper
			case "digit":
				self = .digit
			case "special":
				self = .special
			case "unicode":
				self = .unicode
			default:
				self = .other(description.reduce(into: Set<Character>()) { partialResult, character in
					partialResult.insert(character)
				})
			}
		}

		var description: String {
			switch self {
			case .lower: return "lower"
			case .upper: return "upper"
			case .digit: return "digit"
			case .special: return "special"
			case .unicode: return "unicode"
			case let .other(set): return set.sorted().map(String.init).joined()
			}
		}

		var symbol: String? {
			switch self {
			case .lower: return "textformat.abc"
			case .upper: return "abc"
			case .digit: return "textformat.123"
			case .special: return "command"
			default: return nil
			}
		}

		var id: String { self.description }

		var isPredefined: Bool {
			switch self {
			case .lower, .upper, .digit, .special, .unicode:
				return true
			default:
				return false
			}
		}

		static let allCases: [Rule.PasswordCharacter] = [.upper, .lower, .digit, .special, .unicode, .other(.init())]

		static func < (lhs: Rule.PasswordCharacter, rhs: Rule.PasswordCharacter) -> Bool {
			switch (lhs.isPredefined, rhs.isPredefined) {
			case (false, false):
				guard case let .other(set1) = lhs, case let .other(set2) = rhs else { return false }
				return set1.sorted().map(String.init).joined() < set2.sorted().map(String.init).joined()
			case (false, true):
				return false
			case (true, false):
				return true
			case (true, true):
				return (self.allCases.firstIndex(of: lhs) ?? 0) < (self.allCases.firstIndex(of: rhs) ?? 0)
			}
		}
	}
}

extension Rule {
	init(domain: String, rule originalRule: String) {
		self = Self(id: domain, originalRule: originalRule)
		for split in originalRule.split(separator: /;(?: |$)/, omittingEmptySubsequences: true) {
			let split = String(split).split(separator: /: ?/, maxSplits: 1)
			if split.count != 2 { continue }
			switch split[0] {
			case "minlength":
				self.minLength = Int(split[1].trimmingCharacters(in: .punctuationCharacters))
			case "maxlength":
				self.maxLength = Int(split[1].trimmingCharacters(in: .punctuationCharacters))
			case "required":
				for set in String(split[1]).split(separator: try! Regex(",(?: |$)")) {
					if let set = PasswordCharacter(String(set)) {
						self.required.insert(set)
					}
				}
			case "allowed":
				for set in String(split[1]).split(separator: try! Regex(",(?: |$)")) {
					if let set = PasswordCharacter(String(set)) {
						self.allowed.insert(set)
					}
				}
			default:
				print("did not parse \(split[0])")
			}
		}
		// if it's required, it's always allowed
		self.allowed.subtract(self.required)
	}
}

extension CharacterSet {
	static let descriptionRegex = /\((.*)\)|Predefined (.*) Set/

	var contents: String {
		let matches = try? Self.descriptionRegex.firstMatch(in: description)
		return (matches?.1 ?? matches?.2)?.replacingOccurrences(of: "U+", with: "\\u").applyingTransform(.init("Hex/Unicode-Any"), reverse: false)?.lowercased() ?? description
	}
}

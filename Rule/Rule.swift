import Foundation

struct Rule: Identifiable, Hashable {
	let id: String
	let originalRule: String

	var minLength: Int?
	var maxLength: Int?
	var required = Set<PasswordCharacter>()
	var allowed = Set<PasswordCharacter>()

	var sumLength: Int { (self.minLength ?? 0) + (self.maxLength ?? 0) }

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
				guard description.hasPrefix("[") && description.hasSuffix("]") else { return nil }
				var chars = Set<Character>()
				var i = description.index(after: description.startIndex)
				let end = description.index(before: description.endIndex)
				while i < end {
					if description[i] == "\\" {
						let next = description.index(after: i)
						if next < end {
							chars.insert(description[next])
							i = description.index(after: next)
						} else {
							i = next
						}
					} else {
						chars.insert(description[i])
						i = description.index(after: i)
					}
				}
				self = .other(chars)
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
		for property in Self.splitOutsideClass(originalRule, on: ";") {
			guard let colonIdx = property.firstIndex(of: ":") else { continue }
			let key = property[..<colonIdx].trimmingCharacters(in: .whitespaces)
			let value = String(property[property.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
			switch key {
			case "minlength":
				self.minLength = Int(value)
			case "maxlength":
				self.maxLength = Int(value)
			case "required":
				for token in Self.splitOutsideClass(value, on: ",") {
					if let char = PasswordCharacter(token) { self.required.insert(char) }
				}
			case "allowed":
				for token in Self.splitOutsideClass(value, on: ",") {
					if let char = PasswordCharacter(token) { self.allowed.insert(char) }
				}
			default:
				print("did not parse \(key)")
			}
		}
		// if it's required, it's always allowed
		self.allowed.subtract(self.required)
	}

	// Split s on delimiter characters that appear outside [...] character classes.
	// Inside [...], backslash escapes the next character (preventing it from closing the class).
	private static func splitOutsideClass(_ s: String, on delimiter: Character) -> [String] {
		var result: [String] = []
		var current = ""
		var inClass = false
		var i = s.startIndex
		while i < s.endIndex {
			let c = s[i]
			if inClass {
				if c == "\\" {
					current.append(c)
					i = s.index(after: i)
					if i < s.endIndex {
						current.append(s[i])
						i = s.index(after: i)
					}
				} else {
					if c == "]" { inClass = false }
					current.append(c)
					i = s.index(after: i)
				}
			} else {
				if c == "[" {
					inClass = true
					current.append(c)
					i = s.index(after: i)
				} else if c == delimiter {
					let trimmed = current.trimmingCharacters(in: .whitespaces)
					if !trimmed.isEmpty { result.append(trimmed) }
					current = ""
					i = s.index(after: i)
					while i < s.endIndex && s[i] == " " { i = s.index(after: i) }
				} else {
					current.append(c)
					i = s.index(after: i)
				}
			}
		}
		let trimmed = current.trimmingCharacters(in: .whitespaces)
		if !trimmed.isEmpty { result.append(trimmed) }
		return result
	}
}

extension CharacterSet {
	static let descriptionRegex = /\((.*)\)|Predefined (.*) Set/

	var contents: String {
		let matches = try? Self.descriptionRegex.firstMatch(in: description)
		return (matches?.1 ?? matches?.2)?.replacingOccurrences(of: "U+", with: "\\u").applyingTransform(.init("Hex/Unicode-Any"), reverse: false)?.lowercased() ?? description
	}
}

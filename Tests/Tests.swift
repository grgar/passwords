@testable import Passwords_Inspector
import XCTest

final class Tests: XCTestCase {
	func testRuleParse1() throws {
		let rule = Rule(domain: "admiral.com", rule: "minlength: 8; required: digit; required: [- !\"#$&'()*+,.:;<=>?@[^_`{|}~]]; allowed: lower, upper;")
		XCTAssertEqual(rule.minLength, .some(8), "minLength")
		XCTAssertEqual(rule.maxLength, nil, "maxLength")
		XCTAssertEqual(rule.required, Set<Rule.PasswordCharacter>(arrayLiteral: .digit, .other(.init("- !\"#$&'()*+,.:;<=>?@[^_`{|}~]"))))
		XCTAssertEqual(rule.allowed, Set<Rule.PasswordCharacter>(arrayLiteral: .lower, .upper))
	}
	func testRuleParse2() throws {
		let rule = Rule(domain: "hotels.com", rule: "minlength: 6; maxlength: 20; required: digit; allowed: lower, upper, [@$!#()&^*%];")
		XCTAssertEqual(rule.minLength, .some(6), "minLength")
		XCTAssertEqual(rule.maxLength, .some(20), "maxLength")
		XCTAssertEqual(rule.required, Set<Rule.PasswordCharacter>(arrayLiteral: .digit))
		XCTAssertEqual(rule.allowed, Set<Rule.PasswordCharacter>(arrayLiteral: .lower, .upper, .other(.init("@$!#()&^*%"))))
	}

	func testRuleParseEscapedCloseBracket() throws {
		// \] inside a character class is a literal ] and must not close the class early
		let rule = Rule(domain: "example.com", rule: "required: [a\\]b];")
		XCTAssertEqual(rule.required, Set<Rule.PasswordCharacter>(arrayLiteral: .other(.init("a]b"))))
	}

	func testRuleParseOpenBracketInsideClass() throws {
		// [ inside a character class is a literal character
		let rule = Rule(domain: "example.com", rule: "required: [a[b];")
		XCTAssertEqual(rule.required, Set<Rule.PasswordCharacter>(arrayLiteral: .other(.init("a[b"))))
	}

	func testRuleParseSemicolonInsideClass() throws {
		// ; inside a class followed by even remaining bracket count previously caused an incorrect split
		let rule = Rule(domain: "example.com", rule: "minlength: 6; allowed: [a[;b]]; required: digit;")
		XCTAssertEqual(rule.minLength, .some(6))
		XCTAssertEqual(rule.required, Set<Rule.PasswordCharacter>(arrayLiteral: .digit))
		XCTAssertEqual(rule.allowed, Set<Rule.PasswordCharacter>(arrayLiteral: .other(.init("a[;b]"))))
	}
}

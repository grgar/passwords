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
}

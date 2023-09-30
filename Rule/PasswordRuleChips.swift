import SwiftUI

struct PasswordRuleChips: View {
	let rule: Rule

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			HStack(spacing: 0) {
				if let minLength = rule.minLength {
					Image(systemName: "\(minLength).square")
				}
				if rule.minLength != nil && rule.maxLength != nil {
					Text("–")
				}
				if let maxLength = rule.maxLength {
					Image(systemName: "\(maxLength).square")
				}
			}
			ForEach(rule.required.sorted()) { set in
				if let symbol = set.symbol {
					Image(systemName: symbol)
				} else {
					Text(set.description)
				}
			}
			.font(.caption)
		}
		.symbolRenderingMode(.hierarchical)
	}
}

#Preview {
	List {
		LabeledContent {} label: {
			Text("A")
			PasswordRuleChips(rule: .init(domain: "example.com", rule: "minlength: 2; maxlength: 10; required: upper, lower; allowed: lower"))
		}
	}
}

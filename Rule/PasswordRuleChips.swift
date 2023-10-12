import SwiftUI

struct PasswordRuleChips: View {
	let rule: Rule
	
	struct Length: View {
		let min: Int?
		let max: Int?

		var body: some View {
			HStack(spacing: 0) {
				if let min {
					Image(systemName: "\(min).square")
				} else {
					Image(systemName: "square")
						.foregroundStyle(.quaternary)
				}
				Text("–")
				if let max {
					if max <= 50 {
						Image(systemName: "\(max).square")
					} else {
						Text(max.description)
							.font(.caption)
							.padding(.horizontal, 2)
					}
				} else {
					Image(systemName: "square")
						.foregroundStyle(.quaternary)
				}
			}
		}
	}

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			Length(min: rule.minLength, max: rule.maxLength)
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

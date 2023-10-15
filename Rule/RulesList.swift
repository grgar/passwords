import SwiftUI

struct RulesList: View {
	let rules: [Rule]
	let showFavicon: Bool

	var body: some View {
		List {
			ForEach(rules) { rule in
				NavigationLink {
					PasswordRuleDetail(rule: rule)
				} label: {
					Label {
						LabeledContent {} label: {
							Text(rule.id)
							PasswordRuleChips(rule: rule)
							#if os(watchOS)
								.fixedSize(horizontal: true, vertical: true)
							#endif
						}
					} icon: {
						if showFavicon {
							Favicon(domain: rule.id)
						}
					}
				}
			}
		}
		.listStyle(.plain)
	}
}

#Preview {
	RulesList(rules: [], showFavicon: true)
}

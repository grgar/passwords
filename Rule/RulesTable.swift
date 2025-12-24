import SwiftUI

@available(watchOS, unavailable)
struct RulesTable: View {
	let rules: [Rule]
	let showFavicon: Bool
	let faviconHeight: Double
	@Binding var sortOrder: [KeyPathComparator<Rule>]

	@State private var selection: Rule.ID?

	var body: some View {
		Table(of: Rule.self, selection: $selection, sortOrder: $sortOrder) {
			TableColumn("Domain", value: \.id) { domain in
				HStack {
					if showFavicon {
						Favicon(domain: domain.id)
							.frame(maxHeight: faviconHeight)
					}
					Text(domain.id)
				}
			}

			TableColumn("Length", value: \.sumLength) { domain in
				if showFavicon {
					PasswordRuleChips.Length(min: domain.minLength, max: domain.maxLength)
						.symbolVariant(.fill)
						.symbolRenderingMode(.hierarchical)
						.font(.title)
				} else {
					Text("\(domain.minLength?.description ?? "?") – \(domain.maxLength?.description ?? "?")")
				}
			}
			.width(min: 48, ideal: 48, max: 64)

			TableColumn("Required") { domain in
				HStack {
					ForEach(domain.required.sorted()) { set in
						if let symbol = set.symbol {
							Image(systemName: symbol)
						} else {
							Text(set.description)
						}
					}
				}
			}
			TableColumn("Allowed") { domain in
				HStack {
					ForEach(domain.allowed.sorted()) { set in
						if let symbol = set.symbol {
							Image(systemName: symbol)
						} else {
							Text(set.description)
						}
					}
				}
			}
		} rows: {
			ForEach(rules) { rule in
				TableRow(rule)
			}
		}
		.navigationDestination(isPresented: Binding(get: { selection != nil }, set: { if !$0 { selection = nil } })) {
			if let rule = rules.first(where: { $0.id == selection }) {
				PasswordRuleDetail(rule: rule)
					.navigationSplitViewColumnWidth(min: 320, ideal: 640)
			}
		}
	}
}

#Preview {
	RulesTable(rules: [], showFavicon: true, faviconHeight: 16, sortOrder: .constant([]))
}

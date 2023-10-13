import SwiftUI

struct PasswordRules: View {
	struct IngestRule: Codable {
		let rule: String

		enum CodingKeys: String, CodingKey {
			case rule = "password-rules"
		}
	}

	@State var showHelp = false

	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	private var isCompact: Bool { horizontalSizeClass == .compact }
	#else
	private let isCompact = false
	#endif

	@ScaledMetric(wrappedValue: 24, relativeTo: .body) private var faviconHeight
	
	@AppStorage("showFavicon") private var showFavicon = true
	
	@State private var sortOrder = [KeyPathComparator(\Rule.id)]
//	@State private var tableSelection: Rule?

	var body: some View {
		let responses = response
			.filter { searchText == "" || $0.id.localizedCaseInsensitiveContains(searchText) }
			.sorted(using: sortOrder)

		Group {
			if isCompact {
				List {
					ForEach(responses) { rule in
						NavigationLink {
							PasswordRuleDetail(rule: rule)
						} label: {
							Label {
								LabeledContent {} label: {
									Text(rule.id)
									PasswordRuleChips(rule: rule)
								}
							} icon: {
								Favicon(domain: rule.id)
							}
						}
					}
				}
				.listStyle(.plain)
			} else {
				Table(of: Rule.self, sortOrder: $sortOrder) {
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
					ForEach(responses) { rule in
						TableRow(rule)
					}
				}
//				.navigationDestination(item: $tableSelection) { rule in
//					PasswordRuleDetail(rule: rule)
//				}
			}
		}
		.toolbar {
			ToolbarItemGroup(placement: .automatic) {
				Picker("Favicon", selection: $showFavicon) {
					Label("Show", systemImage: "checklist.unchecked").tag(true)
					Label("Hide", systemImage: "list.bullet").tag(false)
				}
				.pickerStyle(.segmented)
			}
		}
		.loadResource(response: [Rule]()) { $0.map { Rule(domain: $0.key, rule: $0.value.rule) } }
		.navigationTitle(Text("Password Rules"))
		#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Local") {
	NavigationStack {
		PasswordRules(response: [.init(id: "example.com", originalRule: "maxlength: 5;")])
	}
}

#Preview("Remote") {
	NavigationStack {
		PasswordRules()
	}
}

#Preview("Table", traits: .fixedLayout(width: 960, height: 640)) {
	PasswordRules()
}

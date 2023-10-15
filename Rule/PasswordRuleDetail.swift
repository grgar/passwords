import SwiftUI

struct PasswordRuleDetail: View {
	let rule: Rule

	var body: some View {
		List {
			Section {
				if rule.minLength != nil || rule.maxLength != nil {
					HStack(alignment: .firstTextBaseline) {
						if let min = rule.minLength {
							VStack {
								Image(systemName: "\(min).square.fill")
									.font(.largeTitle)
								Text("min")
							}
						}
						if rule.minLength != nil && rule.maxLength != nil {
							Text("–")
								.font(.largeTitle)
								.foregroundStyle(.secondary)
						}
						if let min = rule.maxLength {
							VStack {
								Image(systemName: "\(min).square.fill")
									.font(.largeTitle)
								Text("max")
							}
						}
					}
					.foregroundStyle(.foreground, .quaternary)
					.symbolRenderingMode(.palette)
					.frame(maxWidth: .infinity)
				} else {
					Text("Unspecified")
				}
			} header: {
				Text("Length")
			}
			#if os(macOS)
			.listRowSeparator(.hidden)
			#endif

			Section {
				Grid {
					#if !os(watchOS)
					GridRow {
						Text("")
							.accessibilityHidden(true)
							.gridCellUnsizedAxes([.horizontal, .vertical])
							.gridColumnAlignment(.trailing)
						Color.clear
							.gridCellUnsizedAxes(.vertical)
							.gridColumnAlignment(.leading)
						Text("Required")
						Text("Allowed")
					}
					.font(.caption)
					#else
					GridRow {
						#if !os(watchOS)
						Text("")
							.gridCellUnsizedAxes([.horizontal, .vertical])
							.gridColumnAlignment(.trailing)
						#endif
						Color.clear
							.gridCellUnsizedAxes(.vertical)
							.gridColumnAlignment(.leading)
						Text("")
							.gridCellUnsizedAxes([.horizontal, .vertical])
						Text("")
							.gridCellUnsizedAxes([.horizontal, .vertical])
					}
					.font(.caption)
					.frame(height: 0)
					.accessibilityHidden(true)
					#endif

					ForEach(rule.required.sorted()) { required in
						GridRow {
							if let symbol = required.symbol {
								#if os(watchOS)
								switch required {
								case let .other(set):
									Text("\(Image(systemName: symbol)) \(set.sorted().map(String.init).joined())")
								default:
									Text("\(Image(systemName: symbol)) \(required.description)")
								}
								#else
								Image(systemName: symbol)
								#endif
							} else {
								#if os(watchOS)
								switch required {
								case let .other(set):
									Text(set.sorted().map(String.init).joined())
								default:
									Text(required.description)
								}
								#else
								Text("")
									.accessibilityHidden(true)
									.gridCellUnsizedAxes([.horizontal, .vertical])
								#endif
							}
							#if !os(watchOS)
							switch required {
							case let .other(set):
								Text(set.sorted().map(String.init).joined())
							default:
								Text(required.description)
							}
							#endif
							Image(systemName: "checkmark.circle.fill")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.foreground, .quaternary)
							Image(systemName: "checkmark.circle.fill")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.foreground, .quaternary)
						}
						.padding(.vertical, 2)
					}

					ForEach((rule.allowed.subtracting(rule.required)).sorted()) { required in
						GridRow {
							if let symbol = required.symbol {
								#if os(watchOS)
								switch required {
								case let .other(set):
									Text("\(Image(systemName: symbol)) \(set.sorted().map(String.init).joined())")
								default:
									Text("\(Image(systemName: symbol)) \(required.description)")
								}
								#else
								Image(systemName: symbol)
								#endif
							} else {
								#if os(watchOS)
								switch required {
								case let .other(set):
									Text(set.sorted().map(String.init).joined())
								default:
									Text(required.description)
								}
								#else
								Text("")
									.accessibilityHidden(true)
									.gridCellUnsizedAxes([.horizontal, .vertical])
								#endif
							}
							#if !os(watchOS)
							switch required {
							case let .other(set):
								Text(set.sorted().map(String.init).joined())
							default:
								Text(required.description)
							}
							#endif
							Text("")
								.accessibilityHidden(true)
							Image(systemName: "checkmark.circle.fill")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.foreground, .quaternary)
						}
						.padding(.vertical, 2)
					}
				}
				.padding(.vertical, 8)
			} header: {
				#if os(watchOS)
				VStack(alignment: .leading) {
					Text("Characters")
					HStack {
						Spacer()
						Text("Required")
						Text("Allowed")
					}
					.font(.caption2)
				}
				#else
				Text("Characters")
				#endif
			}
		}
		.navigationTitle(rule.id)
		#if os(iOS)
			.navigationBarTitleDisplayMode(.large)
		#endif
	}
}

#Preview("Demo") {
	PasswordRuleDetail(rule: .init(
		id: "example.com", originalRule: "one: two; three: four; five: six;",
		minLength: 8, maxLength: 16,
		required: .init(arrayLiteral: .lower, .upper, .digit),
		allowed: .init(arrayLiteral: .lower, .upper, .digit, .special, .unicode, .other(.init(arrayLiteral: "a", "b")))
	))
}

#Preview("admiral.com") {
	PasswordRuleDetail(rule: .init(
		domain: "admiral.com",
		rule: "minlength: 8; required: digit; required: [- !\"#$&'()*+,.:;<=>?@[^_`{|}~]]; allowed: lower, upper;"
	))
}

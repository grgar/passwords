import SwiftUI

struct AppEntryRow: View {
	let entry: AppIDCredentials.AppEntry
	@State private var appInfo: AppStoreInfo?

	var bundleID: String {
		let parts = entry.id.split(separator: ".", maxSplits: 1)
		guard parts.count == 2 else { return entry.id }
		let prefix = String(parts[0])
		// Team IDs are uppercase alphanumeric; bundle ID first components are lowercase (com, net, org…)
		guard prefix.allSatisfy({ $0.isUppercase || $0.isNumber }) else { return entry.id }
		return String(parts[1])
	}

	var body: some View {
		Label {
			#if os(macOS)
			HStack(alignment: .top) {
				VStack(alignment: .leading) {
					if let name = appInfo?.appName {
						Text(name)
							.font(.headline)
					}
					Text(entry.id)
				}
				Spacer()
				VStack(alignment: .trailing) {
					ForEach(entry.domains, id: \.self) { domain in
						Text(domain)
							.foregroundStyle(.secondary)
					}
				}
			}
			.padding(.horizontal)
			#else
			if let name = appInfo?.appName {
				Text(name)
			}
			Text(entry.id)
			ForEach(entry.domains, id: \.self) { domain in
				Text(domain)
			}
			#endif
		} icon: {
			Group {
				if let iconURL = appInfo?.iconURL {
					AsyncImage(url: iconURL) { image in
						image.resizable().scaledToFill()
					} placeholder: {
						Color.secondary.opacity(0.2)
					}
				} else {
					Color.secondary.opacity(0.2)
				}
			}
			.frame(width: 30, height: 30)
			.clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
		}
		.task {
			guard appInfo == nil else { return }
			appInfo = await AppStoreInfo.fetch(bundleID: bundleID)
		}
		.padding(.bottom, 8)
	}
}
#Preview {
	List {
		AppEntryRow(entry: .init(id: "P7SDVXUZPK.com.etrade.mobileproiphone", domains: ["etrade.com"]))
		AppEntryRow(entry: .init(id: "com.example.App", domains: ["example.com"]))
		AppEntryRow(entry: .init(id: "P7SDVXUZPK.com.etrade.mobileproiphone", domains: ["etrade.com"]))
		AppEntryRow(entry: .init(id: "com.example.App", domains: ["example.com", "example.net"]))
	}
}

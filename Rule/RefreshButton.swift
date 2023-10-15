import SwiftUI

struct RefreshButton: View {
	@Binding var isError: Bool

	@Environment(\.refresh) private var refresh

	var body: some View {
		Button {
			isError = false
			Task {
				await refresh?()
			}
		} label: {
			Text("Retry")
		}
	}
}

#Preview {
	RefreshButton(isError: .constant(false))
}

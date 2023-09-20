import SwiftUI

struct ContentView: View {
	@State private var path = NavigationPath()
	
	var body: some View {
		NavigationSplitView {
			List {
				Text("a")
			}
			.listStyle(.sidebar)
		} detail: {
			NavigationStack(path: $path) {
				Text("b")
			}
		}
	}
}

#Preview {
	ContentView()
}

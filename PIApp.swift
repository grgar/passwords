import SwiftUI
#if os(iOS)
import BackgroundTasks
#endif

@main
struct PIApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
#if os(iOS)
				.task {
					DataRefresher.scheduleBackgroundRefresh()
				}
#endif
		}
#if os(iOS)
		.backgroundTask(.appRefresh(DataRefresher.taskIdentifier)) {
			await DataRefresher.refreshAllEndpoints()
			DataRefresher.scheduleBackgroundRefresh()
		}
#endif
	}
}

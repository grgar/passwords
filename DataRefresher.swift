import Foundation
#if os(iOS)
import BackgroundTasks
#endif

extension URLCache {
	func isStale(for url: URL, olderThan interval: TimeInterval = 86_400) -> Bool {
		let request = URLRequest(url: url)
		guard
			let cached = cachedResponse(for: request),
			let http = cached.response as? HTTPURLResponse,
			let dateString = http.allHeaderFields["Date"] as? String
		else { return true }
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
		guard let date = formatter.date(from: dateString) else { return true }
		return Date().timeIntervalSince(date) > interval
	}
}

enum DataRefresher {
	static let taskIdentifier = "com.georgegarside.passwordsinspector.refresh"
	static let staleInterval: TimeInterval = 86_400

	static func refreshAllEndpoints() async {
		await withTaskGroup(of: Void.self) { group in
			group.addTask { _ = await PasswordRules.reload(cache: .reloadIgnoringLocalCacheData) }
			group.addTask { _ = await ChangePasswordURLs.reload(cache: .reloadIgnoringLocalCacheData) }
			group.addTask { _ = await SharedCredentials.reload(cache: .reloadIgnoringLocalCacheData) }
			group.addTask { _ = await SharedCredentials.reloadFrom(SharedCredentials.historicalURL, cache: .reloadIgnoringLocalCacheData) }
			group.addTask { _ = await Appended2FA.reload(cache: .reloadIgnoringLocalCacheData) }
			group.addTask { _ = await EmbeddedThirdParty.reload(cache: .reloadIgnoringLocalCacheData) }
			group.addTask { _ = await AppIDCredentials.reload(cache: .reloadIgnoringLocalCacheData) }
			group.addTask { _ = await BrowserCatalogue.reload(cache: .reloadIgnoringLocalCacheData) }
		}
	}

	#if os(iOS)
	static func scheduleBackgroundRefresh() {
		let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
		request.earliestBeginDate = Date(timeIntervalSinceNow: staleInterval)
		try? BGTaskScheduler.shared.submit(request)
	}
	#endif
}

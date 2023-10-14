import SwiftUI

struct HomeBackground: View {
	static let scale: Int = {
		#if os(macOS)
		return 48
		#else
		return 64
		#endif
	}()
	
	static let padding: CGSize = {
		#if os(tvOS)
		return .init(width: 96, height: 96)
		#else
		return .init(width: 12, height: 24)
		#endif
	}()
	
	var body: some View {
		GeometryReader { geometry in
			Image(systemName: "key.fill", size: .init(width: Self.scale, height: Self.scale), padding: Self.padding)
				.resizable(resizingMode: .tile)
				.modifier(InvertIfDark())
				.opacity(0.05)
				.frame(width: geometry.size.width * 2, height: geometry.size.height * 2)
				.rotationEffect(.radians(-0.3))
				.offset(x: -geometry.size.width * 0.5, y: -geometry.size.height * 0.5)
		}
	}
}

struct InvertIfDark: ViewModifier {
	@Environment(\.colorScheme) private var colorScheme

	func body(content: Content) -> some View {
		if colorScheme == .dark {
			content.colorInvert()
		} else {
			content
		}
	}
}

#if canImport(AppKit)
typealias UIImage = NSImage
#endif

extension Image {
	#if canImport(AppKit)
	init(uiImage: UIImage) {
		self.init(nsImage: uiImage)
	}
	#endif

	init(systemName: String, size: CGSize, padding: CGSize = .zero) {
		self.init(uiImage: UIImage(systemName: systemName)!.resizeImage(targetSize: size).addImagePadding(padding: padding))
	}
}

extension UIImage {
	#if canImport(AppKit)
	convenience init?(systemName: String) {
		self.init(systemSymbolName: systemName, accessibilityDescription: nil)
	}
	#endif

	func resizeImage(targetSize: CGSize) -> UIImage {
		let scale = min(targetSize.width / size.width, targetSize.height / size.height)
		let newSize = size.applying(.init(scaleX: scale, y: scale))
		#if canImport(AppKit)
		return UIImage(size: newSize, flipped: false) { rect in
			self.draw(in: rect)
			return true
		}
		#else
		UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
		draw(in: CGRect(origin: .zero, size: newSize))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage!
		#endif
	}

	func addImagePadding(padding: CGSize) -> UIImage {
		let newSize = CGSize(
			width: size.width + padding.width,
			height: size.height + padding.height
		)
		#if canImport(AppKit)
		return UIImage(size: newSize, flipped: false) { rect in
			self.draw(
				in: rect,
				from: rect,
				operation: .copy,
				fraction: 1
			)
			return true
		}
		#else
		UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
		draw(at: CGPoint(x: padding.width / 2, y: padding.height / 2))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage!
		#endif
	}
}

#Preview {
	HomeBackground()
}

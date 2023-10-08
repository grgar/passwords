import SwiftUI

struct HomeBackground: View {
	var body: some View {
		GeometryReader { geometry in
			Image(systemName: "key.fill", size: .init(width: 64, height: 64), padding: .init(width: 12, height: 24))
				.resizable(resizingMode: .tile)
				.modifier(InvertIfDark())
				.opacity(0.05)
				.frame(width: geometry.size.width * 1.5, height: geometry.size.height * 1.5)
				.rotationEffect(.radians(-0.3))
				.offset(x: -geometry.size.width * 0.25, y: -geometry.size.height * 0.25)
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

extension Image {
	init(systemName: String, size: CGSize, padding: CGSize = .zero) {
		self.init(uiImage: UIImage(systemName: systemName)!.resizeImage(targetSize: size).addImagePadding(padding: padding))
	}
}

extension UIImage {
	// https://stackoverflow.com/a/31314494/1549818
	func resizeImage(targetSize: CGSize) -> UIImage {
		let widthRatio = targetSize.width / size.width
		let heightRatio = targetSize.height / size.height

		// Figure out what our orientation is, and use that to form the rectangle
		var newSize: CGSize
		if widthRatio > heightRatio {
			newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
		} else {
			newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
		}

		// This is the rect that we've calculated out and this is what is actually used below
		let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

		// Actually do the resizing to the rect using the ImageContext stuff
		UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
		draw(in: rect)
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage!
	}

	// https://stackoverflow.com/a/39480016/1549818
	func addImagePadding(padding: CGSize) -> UIImage {
		let width = size.width + padding.width
		let height = size.height + padding.height
		let origin = CGPoint(x: (width - size.width) / 2, y: (height - size.height) / 2)
		
		UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
		draw(at: origin)
		let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return imageWithPadding!
	}
}

#Preview {
	HomeBackground()
}

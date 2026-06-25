import Foundation
import SwiftUI
import UIKit

extension Data {
    mutating func appendMultipartField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipartFile(
        name: String,
        fileName: String,
        mimeType: String,
        data: Data,
        boundary: String
    ) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}

extension UIImage {
    func storytopiaPreparedJPEGData(maxDimension: CGFloat = 2048, compressionQuality: CGFloat = 0.82) -> Data? {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else {
            return jpegData(compressionQuality: compressionQuality)
        }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let resized = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized.jpegData(compressionQuality: compressionQuality)
    }
}

extension Color {
    static let storyInk = Color(red: 0.08, green: 0.07, blue: 0.22)
    static let storyGray = Color(red: 0.39, green: 0.39, blue: 0.46)
    static let storyPurple = Color(uiColor: .systemIndigo)
    static let storyLavender = Color(red: 0.91, green: 0.86, blue: 0.98)
    static let storyRose = Color(red: 0.93, green: 0.73, blue: 0.70)
    static let storyBlush = Color(red: 0.99, green: 0.95, blue: 0.92)
    static let storyCream = Color(red: 1.0, green: 0.98, blue: 0.94)
    static let storySoftPink = Color(red: 0.96, green: 0.90, blue: 0.89)
    static let storyPeach = Color(red: 0.93, green: 0.63, blue: 0.45)
    static let storyGold = Color(red: 0.95, green: 0.69, blue: 0.34)
    static let storyBorder = Color(red: 0.88, green: 0.80, blue: 0.78)
    static let homePageBackground = Color(red: 0.949, green: 0.949, blue: 0.969)
    static let homeCardGray = Color(uiColor: .systemGray6)
    static let homeInputGray = Color(red: 0.92, green: 0.92, blue: 0.94)
    static let homeMutedText = Color(red: 0.43, green: 0.44, blue: 0.54)
    static let homeBorder = Color(red: 0.86, green: 0.87, blue: 0.91)
    static let homeAccent = Color(uiColor: .systemIndigo)
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            guard let navigationController = uiViewController.navigationController else {
                return
            }

            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

extension View {
    func enableInteractivePopGesture() -> some View {
        background(InteractivePopGestureEnabler())
    }
}

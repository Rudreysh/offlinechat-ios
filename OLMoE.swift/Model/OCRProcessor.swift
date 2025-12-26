import Foundation
import Vision
import PDFKit
import UIKit

enum OCRProcessor {
    static func recognizeText(in image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            let results = request.results ?? []
            return results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        } catch {
            return ""
        }
    }

    static func recognizeText(in pdfURL: URL, maxPages: Int = 5) async -> String {
        guard let document = PDFDocument(url: pdfURL) else { return "" }
        var output: [String] = []
        let pageCount = min(document.pageCount, maxPages)
        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let pageBounds = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageBounds.size)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageBounds)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            let text = await recognizeText(in: image)
            if !text.isEmpty {
                output.append(text)
            }
        }
        return output.joined(separator: "\n")
    }
}

import Foundation

public enum ComposerMode: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case vision = "Vision"
    case ocr = "OCR"

    public var id: String { rawValue }
}

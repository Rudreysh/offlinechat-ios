import Foundation
import UIKit

public enum ChatAttachmentKind: String {
    case image
    case document
}

public struct ChatAttachment: Identifiable, Equatable {
    public let id: UUID
    public let kind: ChatAttachmentKind
    public let url: URL
    public let filename: String
    public let sizeBytes: Int64

    public init(kind: ChatAttachmentKind, url: URL, filename: String, sizeBytes: Int64) {
        self.id = UUID()
        self.kind = kind
        self.url = url
        self.filename = filename
        self.sizeBytes = sizeBytes
    }

    public var image: UIImage? {
        guard kind == .image else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

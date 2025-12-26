import Foundation

public enum ModelKind: String, Codable {
    case text
    case vision
    case ocrOnly
}

public enum ModelSource: String, Codable {
    case builtIn
    case custom
}

public struct AppModel: Identifiable, Codable, Equatable {
    public var id: String
    public var displayName: String
    public var kind: ModelKind
    public var ggufURL: String?
    public var mmprojURL: String?
    public var ggufFilename: String
    public var mmprojFilename: String?
    public var supportsVision: Bool
    public var supportsOCR: Bool
    public var defaultContext: Int
    public var template: ModelTemplateKind
    public var source: ModelSource
    public var sizeHintMB: Int?

    public init(
        id: String,
        displayName: String,
        kind: ModelKind,
        ggufURL: String?,
        mmprojURL: String? = nil,
        ggufFilename: String,
        mmprojFilename: String? = nil,
        supportsVision: Bool,
        supportsOCR: Bool,
        defaultContext: Int,
        template: ModelTemplateKind,
        source: ModelSource,
        sizeHintMB: Int? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.ggufURL = ggufURL
        self.mmprojURL = mmprojURL
        self.ggufFilename = ggufFilename
        self.mmprojFilename = mmprojFilename
        self.supportsVision = supportsVision
        self.supportsOCR = supportsOCR
        self.defaultContext = defaultContext
        self.template = template
        self.source = source
        self.sizeHintMB = sizeHintMB
    }
}

public extension AppModel {
    var modelFolderURL: URL {
        URL.modelsDirectory.appendingPathComponent(id)
    }

    var localGGUFURL: URL {
        modelFolderURL.appendingPathComponent(ggufFilename)
    }

    var localMMProjURL: URL? {
        guard let mmprojFilename else { return nil }
        return modelFolderURL.appendingPathComponent(mmprojFilename)
    }

    var isDownloaded: Bool {
        localGGUFURL.exists
    }

    var isVisionReady: Bool {
        guard supportsVision, let mmprojURL = localMMProjURL else { return false }
        return localGGUFURL.exists && mmprojURL.exists
    }
}

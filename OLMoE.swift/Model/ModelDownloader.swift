import Foundation
import SwiftUI

public struct ModelDownloadState: Equatable {
    public var progress: Double
    public var isDownloading: Bool
    public var error: String?
    public var downloadedBytes: Int64
    public var totalBytes: Int64

    public init(
        progress: Double = 0,
        isDownloading: Bool = false,
        error: String? = nil,
        downloadedBytes: Int64 = 0,
        totalBytes: Int64 = 0
    ) {
        self.progress = progress
        self.isDownloading = isDownloading
        self.error = error
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
    }
}

@MainActor
public final class ModelDownloader: ObservableObject {
    public static let shared = ModelDownloader()

    @Published public private(set) var states: [String: ModelDownloadState] = [:]

    public func state(for model: AppModel) -> ModelDownloadState {
        states[model.id] ?? ModelDownloadState()
    }

    public func download(model: AppModel) async {
        guard let ggufURLString = model.ggufURL, let ggufURL = URL(string: ggufURLString) else {
            setState(for: model.id, error: "Missing model URL.")
            return
        }

        let artifacts = buildArtifacts(for: model, ggufURL: ggufURL)
        if artifacts.isEmpty {
            setState(for: model.id, error: "No download artifacts.")
            return
        }

        setState(for: model.id, isDownloading: true, progress: 0, error: nil)

        do {
            try FileManager.default.createDirectory(at: model.modelFolderURL, withIntermediateDirectories: true)

            for (index, artifact) in artifacts.enumerated() {
                let baseProgress = Double(index) / Double(artifacts.count)
                try await artifact.url.downloadData(to: artifact.destination) { [weak self] progress in
                    Task { @MainActor in
                        let overall = baseProgress + (progress / Double(artifacts.count))
                        self?.setState(for: model.id, isDownloading: true, progress: overall)
                    }
                }
                if artifact.destination.fileSize < 1_000_000 {
                    throw NSError(domain: "ModelDownloader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is unexpectedly small."])
                }
            }

            setState(for: model.id, isDownloading: false, progress: 1, error: nil)
            ModelStore.shared.refreshDownloadFlags()
        } catch {
            setState(for: model.id, isDownloading: false, progress: 0, error: error.localizedDescription)
        }
    }

    public func deleteLocalFiles(for model: AppModel) {
        do {
            if FileManager.default.fileExists(atPath: model.modelFolderURL.path) {
                try FileManager.default.removeItem(at: model.modelFolderURL)
            }
            setState(for: model.id, isDownloading: false, progress: 0, error: nil)
            ModelStore.shared.refreshDownloadFlags()
        } catch {
            setState(for: model.id, isDownloading: false, progress: 0, error: error.localizedDescription)
        }
    }

    private func buildArtifacts(for model: AppModel, ggufURL: URL) -> [ModelArtifact] {
        var artifacts: [ModelArtifact] = [
            ModelArtifact(kind: .gguf, url: ggufURL, destination: model.localGGUFURL)
        ]

        if model.supportsVision, let mmprojURLString = model.mmprojURL, let mmprojURL = URL(string: mmprojURLString), let mmprojDestination = model.localMMProjURL {
            artifacts.append(ModelArtifact(kind: .mmproj, url: mmprojURL, destination: mmprojDestination))
        }

        return artifacts
    }

    private func setState(for modelID: String, isDownloading: Bool? = nil, progress: Double? = nil, error: String? = nil) {
        var state = states[modelID] ?? ModelDownloadState()
        if let isDownloading { state.isDownloading = isDownloading }
        if let progress { state.progress = progress }
        state.error = error
        states[modelID] = state
    }
}

private struct ModelArtifact {
    enum Kind {
        case gguf
        case mmproj
    }

    let kind: Kind
    let url: URL
    let destination: URL
}

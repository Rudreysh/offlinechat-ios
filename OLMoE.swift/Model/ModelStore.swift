import Foundation
import SwiftUI

@MainActor
public final class ModelStore: ObservableObject {
    public static let shared = ModelStore()

    @Published public private(set) var models: [AppModel] = []
    @Published public var selectedModelID: String? {
        didSet {
            UserDefaults.standard.set(selectedModelID, forKey: Self.selectedModelKey)
        }
    }

    private static let selectedModelKey = "selectedModelID"
    private let modelsFileURL = URL.modelsDirectory.appendingPathComponent("models.json")

    private init() {
        loadModels()
        selectedModelID = UserDefaults.standard.string(forKey: Self.selectedModelKey) ?? models.first?.id
    }

    public func model(withId id: String?) -> AppModel? {
        guard let id else { return nil }
        return models.first { $0.id == id }
    }

    public func setSelectedModel(_ model: AppModel) {
        selectedModelID = model.id
    }

    public func addCustomModel(_ model: AppModel) {
        models.append(model)
        saveModels()
    }

    public func updateModel(_ model: AppModel) {
        if let index = models.firstIndex(where: { $0.id == model.id }) {
            models[index] = model
            saveModels()
        }
    }

    public func removeModel(_ model: AppModel) {
        models.removeAll { $0.id == model.id }
        saveModels()
    }

    public func refreshDownloadFlags() {
        objectWillChange.send()
    }

    private func loadModels() {
        if let data = try? Data(contentsOf: modelsFileURL),
           let decoded = try? JSONDecoder().decode([AppModel].self, from: data) {
            models = mergeDefaults(with: decoded)
            return
        }
        models = Self.defaultModels()
        saveModels()
    }

    private func saveModels() {
        guard let data = try? JSONEncoder().encode(models) else { return }
        try? data.write(to: modelsFileURL, options: [.atomic])
    }

    private func mergeDefaults(with stored: [AppModel]) -> [AppModel] {
        let defaults = Self.defaultModels()
        var merged: [String: AppModel] = Dictionary(uniqueKeysWithValues: defaults.map { ($0.id, $0) })
        let allowedVisionIds = Set(defaults.filter { $0.kind == .vision }.map { $0.id })
        for model in stored {
            if model.kind == .vision && !allowedVisionIds.contains(model.id) {
                continue
            }
            merged[model.id] = model
        }
        let defaultIds = Set(defaults.map { $0.id })
        let custom = stored.filter { model in
            guard !defaultIds.contains(model.id) else { return false }
            if model.kind == .vision {
                return allowedVisionIds.contains(model.id)
            }
            return true
        }
        return defaults.map { merged[$0.id] ?? $0 } + custom
    }

    public static func defaultModels() -> [AppModel] {
        let baseModels: [AppModel] = [
            AppModel(
                id: "olmoe-latest",
                displayName: "OLMoE (Default)",
                kind: .text,
                ggufURL: AppConstants.Model.downloadURL,
                ggufFilename: "\(AppConstants.Model.filename).gguf",
                supportsVision: false,
                supportsOCR: true,
                defaultContext: 4096,
                template: .olmoe,
                source: .builtIn,
                sizeHintMB: 4300
            )
        ]

        let catalogModels: [AppModel] = ModelCatalog.builtIns.map { spec in
            let template: ModelTemplateKind = spec.promptStyle == .gemma ? .gemma : .chatML
            return AppModel(
                id: spec.id,
                displayName: spec.displayName,
                kind: spec.kind == .vision ? .vision : .text,
                ggufURL: spec.model.url.absoluteString,
                mmprojURL: spec.mmproj?.url.absoluteString,
                ggufFilename: spec.model.filename,
                mmprojFilename: spec.mmproj?.filename,
                supportsVision: spec.kind == .vision,
                supportsOCR: true,
                defaultContext: spec.kind == .vision ? 8192 : 4096,
                template: template,
                source: .builtIn,
                sizeHintMB: spec.model.bytes.map { Int($0 / 1_000_000) }
            )
        }

        return baseModels + catalogModels
    }
}

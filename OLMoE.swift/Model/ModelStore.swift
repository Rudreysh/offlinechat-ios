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
        for model in stored {
            merged[model.id] = model
        }
        let defaultIds = Set(defaults.map { $0.id })
        let custom = stored.filter { !defaultIds.contains($0.id) }
        return defaults.map { merged[$0.id] ?? $0 } + custom
    }

    public static func defaultModels() -> [AppModel] {
        [
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
            ),
            AppModel(
                id: "tinyllama-1.1b-chat",
                displayName: "TinyLlama 1.1B (Chat)",
                kind: .text,
                ggufURL: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf?download=true",
                ggufFilename: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
                supportsVision: false,
                supportsOCR: true,
                defaultContext: 2048,
                template: .chatML,
                source: .builtIn,
                sizeHintMB: 700
            ),
            AppModel(
                id: "gemma-2b-it",
                displayName: "Gemma 2B (Instruct)",
                kind: .text,
                ggufURL: "https://huggingface.co/bartowski/Gemma-2B-it-GGUF/resolve/main/Gemma-2B-it-Q4_K_M.gguf?download=true",
                ggufFilename: "Gemma-2B-it-Q4_K_M.gguf",
                supportsVision: false,
                supportsOCR: true,
                defaultContext: 4096,
                template: .chatML,
                source: .builtIn,
                sizeHintMB: 1500
            ),
            AppModel(
                id: "smolvlm2-2.2b",
                displayName: "SmolVLM2 2.2B (Vision)",
                kind: .vision,
                ggufURL: "https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF/resolve/main/SmolVLM2-2.2B-Instruct-Q4_K_M.gguf?download=true",
                mmprojURL: "https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF/resolve/main/mmproj-SmolVLM2-2.2B-Instruct-f16.gguf?download=true",
                ggufFilename: "SmolVLM2-2.2B-Instruct-Q4_K_M.gguf",
                mmprojFilename: "mmproj-SmolVLM2-2.2B-Instruct-f16.gguf",
                supportsVision: true,
                supportsOCR: true,
                defaultContext: 8192,
                template: .chatML,
                source: .builtIn,
                sizeHintMB: 2400
            ),
            AppModel(
                id: "qwen2-vl-2b",
                displayName: "Qwen2-VL 2B (Vision)",
                kind: .vision,
                ggufURL: "https://huggingface.co/ggml-org/Qwen2-VL-2B-Instruct-GGUF/resolve/main/Qwen2-VL-2B-Instruct-Q4_K_M.gguf?download=true",
                mmprojURL: "https://huggingface.co/ggml-org/Qwen2-VL-2B-Instruct-GGUF/resolve/main/mmproj-Qwen2-VL-2B-Instruct-f16.gguf?download=true",
                ggufFilename: "Qwen2-VL-2B-Instruct-Q4_K_M.gguf",
                mmprojFilename: "mmproj-Qwen2-VL-2B-Instruct-f16.gguf",
                supportsVision: true,
                supportsOCR: true,
                defaultContext: 8192,
                template: .chatML,
                source: .builtIn,
                sizeHintMB: 2200
            ),
            AppModel(
                id: "qwen2.5-vl-3b",
                displayName: "Qwen2.5-VL 3B (Vision)",
                kind: .vision,
                ggufURL: "https://huggingface.co/ggml-org/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf?download=true",
                mmprojURL: "https://huggingface.co/ggml-org/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/mmproj-Qwen2.5-VL-3B-Instruct-f16.gguf?download=true",
                ggufFilename: "Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf",
                mmprojFilename: "mmproj-Qwen2.5-VL-3B-Instruct-f16.gguf",
                supportsVision: true,
                supportsOCR: true,
                defaultContext: 8192,
                template: .chatML,
                source: .builtIn,
                sizeHintMB: 3300
            )
        ]
    }
}

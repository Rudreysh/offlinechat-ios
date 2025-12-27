import Foundation

public enum ModelCatalog {
    public struct ModelArtifact {
        public let filename: String
        public let url: URL
        public let sha256: String?
        public let bytes: Int64?

        public init(filename: String, url: URL, sha256: String? = nil, bytes: Int64? = nil) {
            self.filename = filename
            self.url = url
            self.sha256 = sha256
            self.bytes = bytes
        }
    }

    public enum ModelKind {
        case text
        case vision
    }

    public enum PromptStyle {
        case gemma
        case chatML
    }

    public struct ModelSpec: Identifiable {
        public let id: String
        public let displayName: String
        public let kind: ModelKind
        public let model: ModelArtifact
        public let mmproj: ModelArtifact?
        public let promptStyle: PromptStyle
    }

    public static let builtIns: [ModelSpec] = [
        ModelSpec(
            id: "gemma-2b-it",
            displayName: "Gemma 2B (Instruct)",
            kind: .text,
            model: ModelArtifact(
                filename: "gemma-2b-it-Q4_K_M.gguf",
                url: URL(string: "https://huggingface.co/ggml-org/gemma-2b-it-GGUF/resolve/main/gemma-2b-it-Q4_K_M.gguf?download=true")!,
                bytes: 1_500_000_000
            ),
            mmproj: nil,
            promptStyle: .gemma
        ),
        ModelSpec(
            id: "smolvlm2-2.2b",
            displayName: "SmolVLM2 2.2B (Vision)",
            kind: .vision,
            model: ModelArtifact(
                filename: "SmolVLM2-2.2B-Instruct-Q4_K_M.gguf",
                url: URL(string: "https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF/resolve/main/SmolVLM2-2.2B-Instruct-Q4_K_M.gguf?download=true")!,
                bytes: 2_400_000_000
            ),
            mmproj: ModelArtifact(
                filename: "mmproj-SmolVLM2-2.2B-Instruct-Q8_0.gguf",
                url: URL(string: "https://huggingface.co/ggml-org/SmolVLM2-2.2B-Instruct-GGUF/resolve/main/mmproj-SmolVLM2-2.2B-Instruct-Q8_0.gguf?download=true")!,
                bytes: 900_000_000
            ),
            promptStyle: .chatML
        ),
        ModelSpec(
            id: "qwen2-vl-2b-q8",
            displayName: "Qwen2-VL 2B (Vision, Q8_0)",
            kind: .vision,
            model: ModelArtifact(
                filename: "Qwen2-VL-2B-Instruct-Q8_0.gguf",
                url: URL(string: "https://huggingface.co/bartowski/Qwen2-VL-2B-Instruct-GGUF/resolve/main/Qwen2-VL-2B-Instruct-Q8_0.gguf?download=true")!,
                bytes: 2_200_000_000
            ),
            mmproj: ModelArtifact(
                filename: "mmproj-Qwen2-VL-2B-Instruct-f16.gguf",
                url: URL(string: "https://huggingface.co/bartowski/Qwen2-VL-2B-Instruct-GGUF/resolve/main/mmproj-Qwen2-VL-2B-Instruct-f16.gguf?download=true")!,
                bytes: 1_000_000_000
            ),
            promptStyle: .chatML
        ),
        
    ]
}

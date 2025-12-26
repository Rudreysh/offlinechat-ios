import Foundation

public enum LLMError: LocalizedError {
    case modelNotFound
    case missingProjector
    case visionNotAvailable

    public var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Model file not found. Please download it first."
        case .missingProjector:
            return "Vision model requires a projector (mmproj) file."
        case .visionNotAvailable:
            return "Vision is not available in the current runtime."
        }
    }
}

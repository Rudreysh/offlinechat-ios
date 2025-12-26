import Foundation
import UIKit
import llama_mtmd

enum VisionPipeline {
    static func isAvailable() -> Bool {
        llama_mtmd_is_available()
    }

    static func visionPromptMarker() -> String {
        "<image>"
    }
}

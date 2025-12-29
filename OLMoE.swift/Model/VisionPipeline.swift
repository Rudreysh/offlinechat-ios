import Foundation
import UIKit
// mtmd bridge is provided via MTMDShim.swift

enum VisionPipeline {
    static func isAvailable() -> Bool {
        llama_mtmd_is_available()
    }

    static func visionPromptMarker() -> String {
        "<image>"
    }
}

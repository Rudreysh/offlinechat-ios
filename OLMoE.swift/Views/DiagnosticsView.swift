import SwiftUI
import llama_mtmd

struct DiagnosticsView: View {
    @ObservedObject var modelStore: ModelStore

    var body: some View {
        List {
            Section("Runtime") {
                Label("Vision available: \(llama_mtmd_is_available() ? "Yes" : "No")", systemImage: "eye")
            }

            Section("Selected Model") {
                if let model = modelStore.model(withId: modelStore.selectedModelID) {
                    Text(model.displayName)
                    Text("Model file: \(model.localGGUFURL.exists ? "Present" : "Missing")")
                    if model.supportsVision {
                        Text("Projector: \(model.localMMProjURL?.exists == true ? "Present" : "Missing")")
                    }
                } else {
                    Text("No model selected")
                }
            }
        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

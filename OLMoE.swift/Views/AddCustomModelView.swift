import SwiftUI

struct AddCustomModelView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var modelStore: ModelStore
    let existingModel: AppModel?

    @State private var displayName = ""
    @State private var ggufURL = ""
    @State private var mmprojURL = ""
    @State private var supportsVision = false
    @State private var supportsOCR = true
    @State private var contextLength = "4096"
    @State private var errorMessage: String?

    init(modelStore: ModelStore, existingModel: AppModel? = nil) {
        self.modelStore = modelStore
        self.existingModel = existingModel
        _displayName = State(initialValue: existingModel?.displayName ?? "")
        _ggufURL = State(initialValue: existingModel?.ggufURL ?? "")
        _mmprojURL = State(initialValue: existingModel?.mmprojURL ?? "")
        _supportsVision = State(initialValue: existingModel?.supportsVision ?? false)
        _supportsOCR = State(initialValue: existingModel?.supportsOCR ?? true)
        _contextLength = State(initialValue: "\(existingModel?.defaultContext ?? 4096)")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Model") {
                    TextField("Display name", text: $displayName)
                    TextField("GGUF URL", text: $ggufURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Vision") {
                    Toggle("Supports vision", isOn: $supportsVision)
                    TextField("MMProj URL (optional)", text: $mmprojURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .disabled(!supportsVision)
                }

                Section("Options") {
                    Toggle("Supports OCR", isOn: $supportsOCR)
                    TextField("Context length", text: $contextLength)
                        .keyboardType(.numberPad)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle(existingModel == nil ? "Add Custom Model" : "Edit Custom Model")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveModel() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveModel() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a display name."
            return
        }

        guard let ggufURL = URL(string: ggufURL), ggufURL.scheme?.hasPrefix("http") == true else {
            errorMessage = "Please enter a valid GGUF URL."
            return
        }

        let mmprojURLValue: String? = supportsVision ? mmprojURL.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        if supportsVision, let urlString = mmprojURLValue, !urlString.isEmpty, URL(string: urlString) == nil {
            errorMessage = "MMProj URL is invalid."
            return
        }

        let contextValue = Int(contextLength) ?? 4096
        let id = existingModel?.id ?? ("custom-" + UUID().uuidString)
        let ggufFilename = ggufURL.lastPathComponent
        let mmprojFilename = supportsVision ? URL(string: mmprojURLValue ?? "")?.lastPathComponent : nil

        let model = AppModel(
            id: id,
            displayName: trimmedName,
            kind: supportsVision ? .vision : .text,
            ggufURL: ggufURL.absoluteString,
            mmprojURL: (mmprojURLValue?.isEmpty == false) ? mmprojURLValue : nil,
            ggufFilename: ggufFilename,
            mmprojFilename: mmprojFilename,
            supportsVision: supportsVision,
            supportsOCR: supportsOCR,
            defaultContext: contextValue,
            template: .chatML,
            source: .custom,
            sizeHintMB: nil
        )

        if existingModel == nil {
            modelStore.addCustomModel(model)
        } else {
            modelStore.updateModel(model)
        }
        dismiss()
    }
}

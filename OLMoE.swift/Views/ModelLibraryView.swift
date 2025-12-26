import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ModelLibraryView: View {
    @ObservedObject var modelStore: ModelStore
    @ObservedObject var downloader: ModelDownloader
    let onSelectModel: (AppModel) -> Void
    @Binding var showInfoPage: Bool
    @Binding var showMetrics: Bool

    @State private var showAddCustomModel = false
    @State private var showImportLocal = false
    @State private var importError: String?
    @State private var mmprojImportTarget: AppModel?
    @State private var searchText: String = ""
    @State private var editModelTarget: AppModel?

    var body: some View {
        List {
            Section("Text Models") {
                ForEach(filteredModels.filter { $0.kind == .text }) { model in
                    ModelRowView(model: model, downloader: downloader, onSelectModel: onSelectModel, onImportMMProj: { target in
                        mmprojImportTarget = target
                    }, onRemoveModel: removeModel, onEditModel: { editModelTarget = $0 })
                }
            }

            Section("Vision Models") {
                ForEach(filteredModels.filter { $0.kind == .vision }) { model in
                    ModelRowView(model: model, downloader: downloader, onSelectModel: onSelectModel, onImportMMProj: { target in
                        mmprojImportTarget = target
                    }, onRemoveModel: removeModel, onEditModel: { editModelTarget = $0 })
                }
            }

            Section("Custom Models") {
                ForEach(filteredModels.filter { $0.source == .custom }) { model in
                    ModelRowView(model: model, downloader: downloader, onSelectModel: onSelectModel, onImportMMProj: { target in
                        mmprojImportTarget = target
                    }, onRemoveModel: removeModel, onEditModel: { editModelTarget = $0 })
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Models")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Add Custom") { showAddCustomModel = true }
                Button("Import GGUF") { showImportLocal = true }
                NavigationLink("Diagnostics") {
                    DiagnosticsView(modelStore: modelStore)
                }
            }
            AppToolbar(
                leadingContent: {
                    HStack(alignment: .bottom, spacing: 20) {
                        InfoButton(action: { showInfoPage = true })
                        MetricsButton(
                            action: { showMetrics.toggle() },
                            isShowing: showMetrics
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showAddCustomModel) {
            AddCustomModelView(modelStore: modelStore)
        }
        .sheet(isPresented: Binding(get: { editModelTarget != nil }, set: { if !$0 { editModelTarget = nil } })) {
            if let model = editModelTarget {
                AddCustomModelView(modelStore: modelStore, existingModel: model)
            }
        }
        .fileImporter(
            isPresented: $showImportLocal,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importLocalModel(from: url)
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: Binding(get: { mmprojImportTarget != nil }, set: { if !$0 { mmprojImportTarget = nil } }),
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            guard let target = mmprojImportTarget else { return }
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importMMProj(from: url, for: target)
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
            mmprojImportTarget = nil
        }
        .alert("Import Error", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private var filteredModels: [AppModel] {
        guard !searchText.isEmpty else { return modelStore.models }
        return modelStore.models.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    private func importLocalModel(from url: URL) {
        guard url.pathExtension.lowercased() == "gguf" else {
            importError = "Please select a .gguf file."
            return
        }

        let id = "local-" + UUID().uuidString
        let filename = url.lastPathComponent
        let model = AppModel(
            id: id,
            displayName: filename,
            kind: .text,
            ggufURL: nil,
            ggufFilename: filename,
            supportsVision: false,
            supportsOCR: true,
            defaultContext: 4096,
            template: .chatML,
            source: .custom,
            sizeHintMB: nil
        )

        do {
            try FileManager.default.createDirectory(at: model.modelFolderURL, withIntermediateDirectories: true)
            let destination = model.localGGUFURL
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            modelStore.addCustomModel(model)
            modelStore.refreshDownloadFlags()
        } catch {
            importError = error.localizedDescription
        }
    }

    private func importMMProj(from url: URL, for model: AppModel) {
        guard url.pathExtension.lowercased().contains("gguf") else {
            importError = "Please select a .gguf projector file."
            return
        }

        do {
            try FileManager.default.createDirectory(at: model.modelFolderURL, withIntermediateDirectories: true)
            let filename = url.lastPathComponent
            let destination = model.modelFolderURL.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            var updated = model
            updated.mmprojFilename = filename
            modelStore.updateModel(updated)
            modelStore.refreshDownloadFlags()
        } catch {
            importError = error.localizedDescription
        }
    }

    private func removeModel(_ model: AppModel) {
        downloader.deleteLocalFiles(for: model)
        if model.source == .custom {
            modelStore.removeModel(model)
        }
    }
}

private struct ModelRowView: View {
    let model: AppModel
    @ObservedObject var downloader: ModelDownloader
    let onSelectModel: (AppModel) -> Void
    let onImportMMProj: (AppModel) -> Void
    let onRemoveModel: (AppModel) -> Void
    let onEditModel: (AppModel) -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.displayName)
                    .font(.headline)
                if model.supportsVision {
                    Text("Vision")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color("Surface"))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            if let sizeHintMB = model.sizeHintMB {
                Text("~\(sizeHintMB) MB")
                    .font(.caption)
                    .foregroundColor(Color("TextColor").opacity(0.6))
            }

            if model.supportsVision {
                Text(model.isVisionReady ? "Model + projector ready" : "Requires model + projector")
                    .font(.caption)
                    .foregroundColor(Color("TextColor").opacity(0.7))
            } else if model.isDownloaded {
                Text("Downloaded")
                    .font(.caption)
                    .foregroundColor(Color("TextColor").opacity(0.7))
            } else {
                Text("Not downloaded")
                    .font(.caption)
                    .foregroundColor(Color("TextColor").opacity(0.7))
            }

            if state.isDownloading {
                ProgressView(value: state.progress)
                    .progressViewStyle(.linear)
            }

            if let error = state.error {
                HStack(spacing: 8) {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Button {
                        UIPasteboard.general.string = error
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color("AccentColor"))
                }
            }

            HStack(spacing: 12) {
                Button("Select") { onSelectModel(model) }
                    .buttonStyle(.borderedProminent)

                if model.supportsVision && !model.isVisionReady, model.ggufURL != nil {
                    Button("Download") {
                        Task { await downloader.download(model: model) }
                    }
                    .buttonStyle(.bordered)
                } else if model.isDownloaded {
                    Button(model.source == .custom ? "Remove" : "Delete") { showDeleteConfirm = true }
                        .buttonStyle(.bordered)
                } else if model.ggufURL != nil {
                    Button("Download") {
                        Task { await downloader.download(model: model) }
                    }
                    .buttonStyle(.bordered)
                }
                if model.supportsVision && !model.isVisionReady {
                    Button("Import MMProj") { onImportMMProj(model) }
                        .buttonStyle(.bordered)
                }
                if model.source == .custom {
                    Button("Edit") { onEditModel(model) }
                        .buttonStyle(.bordered)
                }
                if state.isDownloading {
                    Button("Cancel") { downloader.cancelDownload(for: model) }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 6)
        .alert("Delete model files?", isPresented: $showDeleteConfirm) {
            Button(model.source == .custom ? "Remove" : "Delete", role: .destructive) {
                onRemoveModel(model)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var state: ModelDownloadState {
        downloader.state(for: model)
    }
}

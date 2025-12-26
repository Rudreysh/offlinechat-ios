import SwiftUI

final class BotLoader: ObservableObject {
    @Published var bot: Bot?
    @Published var errorMessage: String?

    private let useMocked: Bool

    init(model: AppModel, useMocked: Bool) {
        self.useMocked = useMocked
        load(model: model)
    }

    func load(model: AppModel) {
        do {
            bot = try Bot(model: model)
            bot?.loopBackTestResponse = useMocked
            errorMessage = nil
        } catch {
            bot = nil
            errorMessage = error.localizedDescription
        }
    }
}

struct ChatScreen: View {
    let model: AppModel
    @ObservedObject var modelStore: ModelStore
    @Binding var navigationPath: [String]
    @StateObject private var loader: BotLoader
    @State private var modelSwitchError: String?
    @Binding var showMetrics: Bool
    let useMockedModelResponse: Bool
    let disclaimerHandlers: DisclaimerHandlers

    init(
        model: AppModel,
        modelStore: ModelStore,
        navigationPath: Binding<[String]>,
        showMetrics: Binding<Bool>,
        useMockedModelResponse: Bool,
        disclaimerHandlers: DisclaimerHandlers
    ) {
        self.model = model
        self.modelStore = modelStore
        _navigationPath = navigationPath
        _showMetrics = showMetrics
        self.useMockedModelResponse = useMockedModelResponse
        self.disclaimerHandlers = disclaimerHandlers
        _loader = StateObject(wrappedValue: BotLoader(model: model, useMocked: useMockedModelResponse))
    }

    var body: some View {
        Group {
            if let bot = loader.bot {
                BotView(bot, model: model, showMetrics: $showMetrics, disclaimerHandlers: disclaimerHandlers)
            } else if let errorMessage = loader.errorMessage {
                VStack(spacing: 12) {
                    Text("Unable to load model")
                        .font(.title3)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .font(.body)
                    Button("Retry") {
                        loader.load(model: model)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                ProgressView("Loading model...")
            }
        }
        .navigationTitle(model.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(modelStore.models) { candidate in
                        Button(candidate.displayName) {
                            switchModel(candidate)
                        }
                        .disabled(!candidate.isDownloaded)
                    }
                } label: {
                    Label("Model", systemImage: "chevron.down")
                }
            }
        }
        .alert("Model", isPresented: Binding(get: { modelSwitchError != nil }, set: { if !$0 { modelSwitchError = nil } })) {
            Button("OK", role: .cancel) { modelSwitchError = nil }
        } message: {
            Text(modelSwitchError ?? "")
        }
    }

    private func switchModel(_ candidate: AppModel) {
        guard candidate.isDownloaded else {
            modelSwitchError = "Download the model before switching."
            return
        }
        modelStore.setSelectedModel(candidate)
        navigationPath = [candidate.id]
    }
}

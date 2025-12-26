//
//  ContentView.swift
//  OLMoE.swift
//
//  Created by Luca Soldaini on 2024-09-16.
//


import SwiftUI
import os
import PhotosUI
import llama_mtmd

class Bot: LLM {
    static let defaultModelFileURL = URL.modelsDirectory.appendingPathComponent(AppConstants.Model.filename).appendingPathExtension("gguf")
    let modelInfo: AppModel

    init(model: AppModel) throws {
        self.modelInfo = model

        let deviceName = UIDevice.current.model
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let currentDate = dateFormatter.string(from: Date())

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let currentTime = timeFormatter.string(from: Date())

        let systemPrompt = "You are OLMoE (Open Language Mixture of Expert), a small language model running on \(deviceName). You have been developed at the Allen Institute for AI (Ai2) in Seattle, WA, USA. Today is \(currentDate). The time is \(currentTime)."

        guard model.localGGUFURL.exists else {
            throw LLMError.modelNotFound
        }

        print("Loading model: \(model.localGGUFURL.path)")
        if model.supportsVision {
            print("Projector path: \(model.localMMProjURL?.path ?? "none")")
        }

        let template = Template.from(kind: model.template, systemPrompt: systemPrompt)
        super.init(
            from: model.localGGUFURL.path,
            stopSequence: template.stopSequence,
            history: [],
            seed: .random(in: .min ... .max),
            topK: 40,
            topP: 0.95,
            temp: 0.8,
            maxTokenCount: Int32(model.defaultContext)
        )
        self.preprocess = template.preprocess
        self.template = template
    }
}

struct BotView: View {
    @StateObject var bot: Bot
    let model: AppModel
    @State var input = ""
    @State private var isGenerating = false
    @State private var stopSubmitted = false
    @State private var scrollToBottom = false
    @State private var isSharing = false
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var isSharingConfirmationVisible = false
    @State private var isDeleteHistoryConfirmationVisible = false
    @State private var isScrolledToBottom = true
    @FocusState private var isTextEditorFocused: Bool
    @Binding var showMetrics: Bool
    let disclaimerHandlers: DisclaimerHandlers
    @State private var pendingAttachments: [ChatAttachment] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var composerMode: ComposerMode = .chat
    @State private var userAlertMessage: String?

    // Add new state for text sharing
    @State private var showTextShareSheet = false

    private var hasValidInput: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pendingAttachments.isEmpty
    }

    private var isInputDisabled: Bool {
        isGenerating || isSharing
    }

    private var isDeleteButtonDisabled: Bool {
        isInputDisabled || bot.history.isEmpty
    }

    private var isChatEmpty: Bool {
        bot.history.isEmpty && !isGenerating && bot.output.isEmpty
    }

    private var availableComposerModes: [ComposerMode] {
        var modes: [ComposerMode] = [.chat]
        if model.supportsOCR {
            modes.append(.ocr)
        }
        if model.supportsVision {
            modes.insert(.vision, at: 1)
        }
        return modes
    }

    init(_ bot: Bot, model: AppModel, showMetrics: Binding<Bool>, disclaimerHandlers: DisclaimerHandlers) {
        _bot = StateObject(wrappedValue: bot)
        _showMetrics = showMetrics
        self.disclaimerHandlers = disclaimerHandlers
        self.model = model
    }

    func shouldShowScrollButton() -> Bool {
        return !isScrolledToBottom
    }

    func respond() {
        isGenerating = true
        #if targetEnvironment(macCatalyst)
            isTextEditorFocused = true
        #else
            isTextEditorFocused = false
        #endif
        stopSubmitted = false
        let originalInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        input = "" // Clear the input after sending

        // Add the user message to history immediately
        bot.history.append(Chat(role: .user, content: originalInput, attachments: pendingAttachments))

        Task {
            let mode = composerMode
            let attachments = pendingAttachments
            pendingAttachments.removeAll()

            if (mode == .vision || mode == .ocr) && attachments.isEmpty {
                await MainActor.run {
                    userAlertMessage = "Attach an image or document first."
                    isGenerating = false
                    stopSubmitted = false
                }
                return
            }

            if mode == .ocr {
                let ocrText = await runOCR(for: attachments)
                await MainActor.run {
                    bot.history.append(Chat(role: .bot, content: ocrText.isEmpty ? "No text found." : ocrText))
                    bot.setOutput(to: "")
                    isGenerating = false
                    stopSubmitted = false
                }
                return
            }

            if mode == .vision, model.supportsVision {
                if !model.isVisionReady {
                    await MainActor.run {
                        userAlertMessage = LLMError.missingProjector.localizedDescription
                        isGenerating = false
                        stopSubmitted = false
                    }
                    return
                }
            } else if mode == .vision {
                await MainActor.run {
                    userAlertMessage = "Selected model does not support vision."
                    isGenerating = false
                    stopSubmitted = false
                }
                return
            }

            let prompt = await buildPrompt(input: originalInput, mode: mode, attachments: attachments)
            await bot.respond(to: prompt)

            await MainActor.run {
                bot.setOutput(to: "")
                isGenerating = false
                stopSubmitted = false
                #if targetEnvironment(macCatalyst)
                    isTextEditorFocused = true  // Mac Only. Re-focus after response
                #endif
            }
        }
    }

    func stop() {
        self.stopSubmitted = true
        bot.stop()
    }

    func deleteHistory() {
        Task { @MainActor in
            await bot.clearHistory()
            bot.setOutput(to: "")
            input = "" // Clear the input
            pendingAttachments.removeAll()
            // Reset metrics when clearing chat history
            bot.metrics.reset()
        }
    }

    private func formatConversationForSharing() -> String {
        let deviceName = UIDevice.current.model
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        let timestamp = dateFormatter.string(from: Date())

        let header = """
        Conversation with OLMoE (Open Language Mixture of Expert)
        Device: \(deviceName)
        Shared: \(timestamp)
        ----------------------------------------

        """

        let conversation = bot.history.map { chat in
            let role = chat.role == .user ? "User" : "OLMoE"
            return "\(role): \(chat.content)"
        }.joined(separator: "\n\n")

        let footer = """

        ----------------------------------------
        Shared from OLMoE - AI2's Open Language Model
        https://github.com/allenai/OLMoE
        """

        return header + conversation + footer
    }

    private func addDocumentAttachment(from url: URL) {
        let ext = url.pathExtension.isEmpty ? "pdf" : url.pathExtension
        let filename = "Doc-\(UUID().uuidString).\(ext)"
        let destination = URL.attachmentsDirectory.appendingPathComponent(filename)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            let attachment = ChatAttachment(
                kind: .document,
                url: destination,
                filename: destination.lastPathComponent,
                sizeBytes: destination.fileSize
            )
            pendingAttachments.append(attachment)
        } catch {
            userAlertMessage = "Failed to add document: \(error.localizedDescription)"
        }
    }

    private func addPhotoAttachments(from items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            guard let image = UIImage(data: data) else { continue }
            let filename = "Photo-\(UUID().uuidString).jpg"
            let destination = URL.attachmentsDirectory.appendingPathComponent(filename)
            if let jpgData = image.jpegData(compressionQuality: 0.9) {
                try? jpgData.write(to: destination, options: [.atomic])
            } else {
                try? data.write(to: destination, options: [.atomic])
            }
            let attachment = ChatAttachment(
                kind: .image,
                url: destination,
                filename: destination.lastPathComponent,
                sizeBytes: destination.fileSize
            )
            pendingAttachments.append(attachment)
        }
        await MainActor.run {
            selectedPhotos.removeAll()
        }
    }

    private func runOCR(for attachments: [ChatAttachment]) async -> String {
        var output: [String] = []
        for attachment in attachments {
            switch attachment.kind {
            case .image:
                if let image = attachment.image {
                    let text = await OCRProcessor.recognizeText(in: image)
                    if !text.isEmpty {
                        output.append(text)
                    }
                }
            case .document:
                let text = await OCRProcessor.recognizeText(in: attachment.url)
                if !text.isEmpty {
                    output.append(text)
                }
            }
        }
        return output.joined(separator: "\n")
    }

    private func buildPrompt(input: String, mode: ComposerMode, attachments: [ChatAttachment]) async -> String {
        guard !attachments.isEmpty else { return input }

        if mode == .vision {
            if llama_mtmd_is_available() {
                print("Vision runtime available. Using image marker.")
                return "<image>\n\(input)"
            }
            print("Vision runtime not available. Falling back to OCR context.")
            let context = await attachmentContext(from: attachments)
            return "Attached files (extracted context):\n\(context)\n\n\(input)"
        }

        if mode == .ocr {
            let context = await attachmentContext(from: attachments)
            return "Extracted text:\n\(context)\n\n\(input)"
        }

        return input
    }

    private func attachmentContext(from attachments: [ChatAttachment]) async -> String {
        var lines: [String] = []
        for attachment in attachments {
            switch attachment.kind {
            case .image:
                let label = "[Image: \(attachment.filename)]"
                var text = ""
                if let image = attachment.image {
                    text = await OCRProcessor.recognizeText(in: image)
                }
                if text.isEmpty {
                    lines.append("\(label) (no OCR/labels available)")
                } else {
                    lines.append("\(label)\n\(text)")
                }
            case .document:
                let label = "[Document: \(attachment.filename)]"
                let text = await OCRProcessor.recognizeText(in: attachment.url)
                if text.isEmpty {
                    lines.append("\(label) (no OCR available)")
                } else {
                    lines.append("\(label)\n\(text)")
                }
            }
        }
        return lines.joined(separator: "\n\n")
    }

    func shareConversation() {
        isSharing = true
        disclaimerHandlers.setShowDisclaimerPage(false)
        Task {
            do {
                let attestationResult = try await AppAttestManager.performAttest()

                // Prepare payload
                let apiKey = Configuration.apiKey
                let apiUrl = Configuration.apiUrl

                let modelName = AppConstants.Model.filename
                let systemFingerprint = "\(modelName)-\(AppInfo.shared.appId)"

                let messages = bot.history.map { chat in
                    ["role": chat.role == .user ? "user" : "assistant", "content": chat.content]
                }

                let payload: [String: Any] = [
                    "model": modelName,
                    "system_fingerprint": systemFingerprint,
                    "created": Int(Date().timeIntervalSince1970),
                    "messages": messages,
                    "key_id": attestationResult.keyID,
                    "attestation_object": attestationResult.attestationObjectBase64
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: payload)

                guard let url = URL(string: apiUrl), !apiUrl.isEmpty else {
                    print("Invalid URL")
                    await MainActor.run {
                        isSharing = false
                    }
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.httpBody = jsonData
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let responseString = String(data: data, encoding: .utf8)!
                    if let jsonData = responseString.data(using: .utf8),
                       let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let body = jsonResult["body"] as? String,
                       let bodyData = body.data(using: .utf8),
                       let bodyJson = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any],
                       let urlString = bodyJson["url"] as? String,
                       let url = URL(string: urlString) {
                        await MainActor.run {
                            self.shareURL = url
                            self.showShareSheet = true
                        }
                        print("Conversation shared successfully")
                    } else {
                        print("Failed to parse response")
                    }
                } else {
                    print("Failed to share conversation")
                }
            } catch {
                let attestError = error as NSError
                if attestError.domain == "AppAttest" {
                    print("Error: \(attestError.localizedDescription)")
                } else {
                    print("Error sharing conversation: \(error)")
                }
            }

            await MainActor.run {
                isSharing = false
            }
        }
    }

    @ViewBuilder
    func shareButton() -> some View {
        if isSharing {
            SpinnerView(color: Color("AccentColor"))
        } else {
            let isDisabled = isSharing || bot.history.isEmpty || isGenerating
            ToolbarButton(action: {
                isTextEditorFocused = false
                // disclaimerHandlers.setActiveDisclaimer(Disclaimers.ShareDisclaimer())
                // disclaimerHandlers.setCancelAction({ disclaimerHandlers.setShowDisclaimerPage(false) })
                // disclaimerHandlers.setAllowOutsideTapDismiss(true)
                // disclaimerHandlers.setConfirmAction({ shareConversation() })
                // disclaimerHandlers.setShowDisclaimerPage(true)
                showTextShareSheet = true
            }, assetName: "ShareIcon", foregroundColor: Color("AccentColor"))
             .disabled(isDisabled)
        }
    }

    @ViewBuilder
    func newChatButton() -> some View {
        ToolbarButton(action: {
            isTextEditorFocused = false
            isDeleteHistoryConfirmationVisible = true
            stop()
        }, assetName: "NewChatIcon", foregroundColor: Color("LightGreen"))
            .alert("Clear chat history?", isPresented: $isDeleteHistoryConfirmationVisible, actions: {
                Button("Clear", action: deleteHistory)
                Button("Cancel", role: .cancel) {
                    isDeleteHistoryConfirmationVisible = false
                }
            })
            .disabled(isDeleteButtonDisabled)
    }

    var body: some View {
        GeometryReader { geometry in
            contentView(in: geometry)
        }
    }

    private func contentView(in geometry: GeometryProxy) -> some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                if !isChatEmpty {
                    ScrollViewReader { proxy in
                        ZStack {
                            ChatView(
                                history: bot.history,
                                output: bot.output.trimmingCharacters(in: .whitespacesAndNewlines),
                                metrics: bot.metrics,
                                showMetrics: $showMetrics,
                                isGenerating: $isGenerating,
                                isScrolledToBottom: $isScrolledToBottom,
                                stopSubmitted: $stopSubmitted
                            )
                                .onChange(of: scrollToBottom) { _, newValue in
                                    if newValue {
                                        withAnimation {
                                            proxy.scrollTo(ChatView.BottomID, anchor: .bottom)
                                        }
                                        scrollToBottom = false
                                    }
                                }
                                .gesture(TapGesture().onEnded({
                                    isTextEditorFocused = false
                                }))

                            ScrollToBottomButtonView(
                                scrollToBottom: $scrollToBottom,
                                shouldShowScrollButton: shouldShowScrollButton
                            )
                        }
                    }
                } else {
                    ZStack {
                        VStack{
                            Spacer()
                            Image("Ai2Icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: min(geometry.size.width, geometry.size.height) * 0.18)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer()

                if (isChatEmpty) {
                    BotChatBubble(
                        text: String(localized: "Welcome chat message", comment: "Default chat bubble when conversation is empty"),
                        maxWidth: geometry.size.width,
                        hideCopyButton: true
                    )
                    .padding(.bottom, 15)
                }

                MessageInputView(
                    input: $input,
                    isGenerating: $isGenerating,
                    stopSubmitted: $stopSubmitted,
                    selectedPhotos: $selectedPhotos,
                    composerMode: $composerMode,
                    isTextEditorFocused: $isTextEditorFocused,
                    attachments: pendingAttachments,
                    availableModes: availableComposerModes,
                    isInputDisabled: isInputDisabled,
                    hasValidInput: hasValidInput,
                    respond: respond,
                    stop: stop,
                    onDocumentPicked: { url in
                        addDocumentAttachment(from: url)
                    },
                    onRemoveAttachment: { attachment in
                        pendingAttachments.removeAll { $0.id == attachment.id }
                    }
                )
            }
            .padding(12)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ActivityViewController(activityItems: [url])
            }
        }
        .sheet(isPresented: $showTextShareSheet) {
            ActivityViewController(activityItems: [formatConversationForSharing()])
        }
        .gesture(TapGesture().onEnded({
            isTextEditorFocused = false
        }))
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await addPhotoAttachments(from: newItems) }
        }
        .alert("Attachment Error", isPresented: Binding(get: { userAlertMessage != nil }, set: { if !$0 { userAlertMessage = nil } })) {
            Button("OK", role: .cancel) { userAlertMessage = nil }
        } message: {
            Text(userAlertMessage ?? "")
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                #if targetEnvironment(macCatalyst)
                    let spacing: CGFloat = 20
                #else
                    let spacing: CGFloat = 32
                #endif
                HStack(alignment: .bottom, spacing: spacing) {
                    shareButton()
                    newChatButton()
                }
            }
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}


// Add this struct to handle the UIActivityViewController
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

struct ContentView: View {
    @StateObject private var disclaimerState = DisclaimerState()
    @StateObject private var modelStore = ModelStore.shared
    @StateObject private var downloader = ModelDownloader.shared

    @State private var showInfoPage: Bool = false
    @State private var isSupportedDevice: Bool = isDeviceSupported()
    @State private var useMockedModelResponse: Bool = false
    @State private var showMetrics: Bool = false
    @State private var selectionError: String?
    @State private var path: [String] = []

    let logger = Logger(subsystem: "com.allenai.olmoe", category: "ContentView")

    public var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                VStack {
                    if !isSupportedDevice && !useMockedModelResponse {
                        UnsupportedDeviceView(
                            proceedAnyway: { isSupportedDevice = true },
                            proceedMocked: {
                                useMockedModelResponse = true
                            }
                        )
                    } else {
                        ModelLibraryView(modelStore: modelStore, downloader: downloader, onSelectModel: { model in
                            guard model.isDownloaded else {
                                selectionError = "Download the model before starting a chat."
                                return
                            }
                            modelStore.setSelectedModel(model)
                            path.append(model.id)
                        }, showInfoPage: $showInfoPage, showMetrics: $showMetrics)
                    }
                }
                .navigationDestination(for: String.self) { modelID in
                    if let model = modelStore.model(withId: modelID) {
                        ChatScreen(model: model, modelStore: modelStore, navigationPath: $path, showMetrics: $showMetrics, useMockedModelResponse: useMockedModelResponse, disclaimerHandlers: DisclaimerHandlers(
                            setActiveDisclaimer: { self.disclaimerState.activeDisclaimer = $0 },
                            setAllowOutsideTapDismiss: { self.disclaimerState.allowOutsideTapDismiss = $0 },
                            setCancelAction: { self.disclaimerState.onCancel = $0 },
                            setConfirmAction: { self.disclaimerState.onConfirm = $0 },
                            setShowDisclaimerPage: { self.disclaimerState.showDisclaimerPage = $0 }
                        ))
                    } else {
                        Text("Model not found.")
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear {
                disclaimerState.showInitialDisclaimer()
            }
            .sheet(isPresented: $showInfoPage) {
                SheetWrapper {
                    InfoView(isPresented: $showInfoPage)
                }
            }
            .sheet(isPresented: $disclaimerState.showDisclaimerPage) {
                SheetWrapper {
                    DisclaimerPage(
                        message: disclaimerState.activeDisclaimer?.text ?? "",
                        title: disclaimerState.activeDisclaimer?.title ?? "",
                        titleText: disclaimerState.activeDisclaimer?.headerTextContent ?? [],
                        confirm: DisclaimerPage.PageButton(
                            text: disclaimerState.activeDisclaimer?.buttonText ?? "",
                            onTap: {
                                disclaimerState.onConfirm?()
                            }
                        ),
                        cancel: disclaimerState.onCancel.map { cancelAction in
                            DisclaimerPage.PageButton(
                                text: "Cancel",
                                onTap: {
                                    cancelAction()
                                    disclaimerState.activeDisclaimer = nil
                                }
                            )
                        }
                    )
                }
                .interactiveDismissDisabled(!disclaimerState.allowOutsideTapDismiss)
            }
            .alert("Model", isPresented: Binding(get: { selectionError != nil }, set: { if !$0 { selectionError = nil } })) {
                Button("OK", role: .cancel) { selectionError = nil }
            } message: {
                Text(selectionError ?? "")
            }
        }
    }
}

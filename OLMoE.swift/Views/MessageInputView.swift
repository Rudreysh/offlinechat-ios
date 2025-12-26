//
//  MessageInputView.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/19/24.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MessageInputView: View {
    @Binding var input: String
    @Binding var isGenerating: Bool
    @Binding var stopSubmitted: Bool
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var composerMode: ComposerMode
    @FocusState.Binding var isTextEditorFocused: Bool
    let attachments: [ChatAttachment]
    let availableModes: [ComposerMode]
    let isInputDisabled: Bool
    let hasValidInput: Bool
    let respond: () -> Void
    let stop: () -> Void
    let onDocumentPicked: (URL) -> Void
    let onRemoveAttachment: (ChatAttachment) -> Void

    @State private var isFileImporterPresented = false

    var body: some View {
        VStack(spacing: 10) {
            if !attachments.isEmpty {
                AttachmentStrip(attachments: attachments, onRemove: onRemoveAttachment)
            }

            HStack(alignment: .top, spacing: 12) {
                HStack(spacing: 8) {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 4, matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18))
                    }

                    Button {
                        isFileImporterPresented = true
                    } label: {
                        Image(systemName: "paperclip")
                            .font(.system(size: 18))
                    }
                }
                .padding(.top, 16)
                .foregroundColor(Color("TextColor"))

                TextField(
                    UIDevice.current.userInterfaceIdiom == .mac ?
                        String(localized: "Message OLMoE (Press Return to send)") :
                        String(localized: "Message OLMoE"),
                    text: $input,
                    axis: .vertical
                )
                    .scrollContentBackground(.hidden)
                    .multilineTextAlignment(.leading)
                    .lineLimit(10)
                    .foregroundColor(Color("TextColor"))
                    .font(.body())
                    .focused($isTextEditorFocused)
                    .onChange(of: isTextEditorFocused) { _, isFocused in
                        if !isFocused {
                            hideKeyboard()
                        }
                    }
                    .disabled(isInputDisabled)
                    .opacity(isInputDisabled ? 0.6 : 1)
                    .padding(.vertical, 17.5)
                    .onSubmit {
                        #if targetEnvironment(macCatalyst)
                        if hasValidInput {
                            respond()
                        }
                        #endif
                    }
                    .submitLabel(.send)

                ZStack {
                    if isGenerating && !stopSubmitted {
                        Button(action: stop) {
                            Image("StopIcon")
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 12)
                        .padding(.trailing, -12)
                    } else {
                        Button(action: respond) {
                            Image("SendIcon")
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasValidInput)
                        .opacity(hasValidInput ? 1 : 0.5)
                        .foregroundColor(hasValidInput ? Color("LightGreen") : Color("TextColor").opacity(0.5))
                        .keyboardShortcut(.defaultAction)
                        .padding(.top, 20)
                    }
                }
                .onTapGesture {
                    isTextEditorFocused = false
                }
                .font(.system(size: 24))
            }

            if !availableModes.isEmpty {
                Picker("Mode", selection: $composerMode) {
                    ForEach(availableModes) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding([.leading, .trailing], 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color("Surface"))
                .foregroundStyle(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color("LightGreen"), lineWidth: 1)
                .opacity(isTextEditorFocused ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isTextEditorFocused)
        )
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onDocumentPicked(url)
                }
            case .failure:
                break
            }
        }
    }
}

private struct AttachmentStrip: View {
    let attachments: [ChatAttachment]
    let onRemove: (ChatAttachment) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachments) { attachment in
                    AttachmentChip(attachment: attachment, onRemove: onRemove)
                }
            }
        }
    }
}

private struct AttachmentChip: View {
    let attachment: ChatAttachment
    let onRemove: (ChatAttachment) -> Void

    var body: some View {
        HStack(spacing: 8) {
            if attachment.kind == .image, let image = attachment.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "doc.text.fill")
            }
            Text(attachment.filename)
                .lineLimit(1)
                .font(.caption)
            Button(action: { onRemove(attachment) }) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color("Surface").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

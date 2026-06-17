import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CreateEntryView: View {
    private let artStyles = ["Anime", "Graphic Novel", "Pixel Art", "Manga", "Cozy Storybook", "Pop Art", "Colored Journal"]

    @Binding var entryText: String
    @Binding var selectedPage: StoryPage
    @Binding var generatedStoryboards: [GeneratedStoryboard]

    @State private var selectedArtStyle = "Anime"
    private let previewLayout = StoryboardLayoutOption.fiveClassic

    @State private var storyboardPhotos: [UIImage?] = Array(repeating: nil, count: 5)
    @State private var selectedPhotoSlot: Int?
    @State private var isShowingPhotoSourceDialog = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingCamera = false
    @State private var isShowingDraftSavedConfirmation = false
    @State private var isGeneratingStoryboard = false
    @State private var generationErrorMessage: String?
    @State private var isShowingExpandedEditor = false
    @State private var isShowingArtStyleGrid = false
    @State private var storyTitle = ""
    @State private var storyLocation = ""
    @State private var storyDate = Date()
    @State private var savesDraft = true
    @State private var isPrivateEntry = false
    @State private var selectedPhotoPickerItems: [PhotosPickerItem] = []
    @State private var draggedStoryboardPhotoIndex: Int?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isEditorFocused: Bool

    private func dismissKeyboard() {
        isTitleFocused = false
        isEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.homePageBackground
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissKeyboard()
                    }

                layoutPage
                    .toolbar(.hidden, for: .navigationBar)
            }
            .navigationDestination(isPresented: $isShowingExpandedEditor) {
                ExpandedEntryEditor(entryText: $entryText)
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraPhotoPicker { image in
                setStoryboardPhoto(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingArtStyleGrid) {
            ArtStyleGridSheet(
                artStyles: artStyles,
                selectedArtStyle: $selectedArtStyle
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .photosPicker(
            isPresented: $isShowingPhotoLibrary,
            selection: $selectedPhotoPickerItems,
            maxSelectionCount: max(1, storyboardPhotos.filter { $0 == nil }.count),
            selectionBehavior: .ordered,
            matching: .images
        )
        .confirmationDialog(
            "Add Photo",
            isPresented: $isShowingPhotoSourceDialog,
            titleVisibility: .visible
        ) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    selectedPhotoSlot = nextAvailablePhotoSlot
                    isShowingCamera = true
                }
            }

            Button("Photo Library") {
                selectedPhotoSlot = nextAvailablePhotoSlot
                isShowingPhotoLibrary = true
            }

            Button("Cancel", role: .cancel) {
            }
        }
        .alert("Draft saved", isPresented: $isShowingDraftSavedConfirmation) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text("You can keep editing this entry whenever you're ready.")
        }
        .alert(
            "Storyboard generation failed",
            isPresented: Binding(
                get: { generationErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        generationErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(generationErrorMessage ?? "")
        }
        .onChange(of: selectedPhotoPickerItems) { items in
            guard !items.isEmpty else {
                return
            }

            Task {
                await loadPhotoLibraryImages(from: items)
            }
        }
    }

    private func startStoryboardGeneration() {
        guard !isGeneratingStoryboard else {
            return
        }

        let apiKey = OpenAITestConfig.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty, apiKey != "PASTE_OPENAI_API_KEY_HERE" else {
            generationErrorMessage = StoryboardGenerationError.missingAPIKey.localizedDescription
            return
        }

        let photos = storyboardPhotos.compactMap { $0 }
        let layout = StoryboardLayoutOption.fiveClassic
        isGeneratingStoryboard = true

        Task {
            do {
                let image = try await OpenAIImageGenerationService().generateStoryboard(
                    apiKey: apiKey,
                    text: entryText,
                    artStyle: selectedArtStyle,
                    layout: layout,
                    images: photos
                )

                let storyboard = try GeneratedStoryboardStore.persistedStoryboard(
                    image: image,
                    promptText: entryText,
                    artStyle: selectedArtStyle,
                    sourcePhotoCount: photos.count
                )

                await MainActor.run {
                    generatedStoryboards.insert(storyboard, at: 0)
                    GeneratedStoryboardStore.save(generatedStoryboards)
                    isGeneratingStoryboard = false
                    selectedPage = .profile
                }
            } catch {
                await MainActor.run {
                    generationErrorMessage = error.localizedDescription
                    isGeneratingStoryboard = false
                }
            }
        }
    }

    private var layoutPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader

            ScrollView(showsIndicators: false) {
                createEntryContent
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(pageTapBackground)
        }
        .background(Color.homePageBackground)
    }

    private var pageTapBackground: some View {
        Color.homePageBackground
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
    }

    private var pageHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.storyPurple.opacity(0.72))

                Text(storyDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .layoutPriority(1)

            Spacer()

            Button {
                dismissKeyboard()
                isShowingDraftSavedConfirmation = true
            } label: {
                Text("Save Draft")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.storyPurple)
                    .frame(height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private var createEntryContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            storyDetailsStepContent
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private var storyDetailsStepContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            editorCard
            photoStripSection
            // artStylePickerSection
            storyDetailsCard
            entryPrivacyCard
            generateStoryboardButton
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var photoStripSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "paperclip")
                    .font(.system(size: 23, weight: .light))
                    .foregroundStyle(Color.storyInk.opacity(0.86))
                    .rotationEffect(.degrees(-18))
                    .frame(width: 24, height: 24)

                Text("Reference Photos")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer(minLength: 10)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(Array(storyboardPhotos.compactMap { $0 }.enumerated()), id: \.offset) { index, image in
                        StoryboardPhotoStripThumbnail(image: image) {
                            removeStoryboardPhoto(at: index)
                        }
                            .onDrag {
                                draggedStoryboardPhotoIndex = index
                                return NSItemProvider(object: String(index) as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: StoryboardPhotoDropDelegate(
                                    photos: $storyboardPhotos,
                                    draggedIndex: $draggedStoryboardPhotoIndex,
                                    destinationIndex: index
                                )
                            )
                    }

                    if nextAvailablePhotoSlot != nil {
                        Button {
                            dismissKeyboard()
                            selectedPhotoSlot = nextAvailablePhotoSlot
                            isShowingPhotoSourceDialog = true
                        } label: {
                            StoryboardPhotoStripAddButton()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add reference photos")
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.54), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }

    private func photoSourceButton(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            dismissKeyboard()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(Color.storyPurple)
                    .frame(height: 26)

                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.storyInk.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(width: 76, height: 82)
            .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.storyPurple.opacity(0.32), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var storyboardPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("Storyboard Preview")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.storyInk)

                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.storyGold)
                    }

                    Text("Every storyboard uses 5 panels with text")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                }

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    Text("\(previewLayout.title) · 5 panels")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.storyInk.opacity(0.7))

                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.storyPurple)
                }
            }

            storyboardPreviewLayout(previewLayout)
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }

    @ViewBuilder
    private func storyboardPreviewLayout(_ layout: StoryboardLayoutOption) -> some View {
        switch layout {
        case .twoRectangles:
            VStack(spacing: 8) {
                storyboardPhotoPanel(index: 0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)

                storyboardPhotoPanel(index: 1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
            }
        case .threeHorizontalPanels:
            VStack(spacing: 8) {
                ForEach(0..<layout.panelCount, id: \.self) { index in
                    storyboardPhotoPanel(index: index)
                        .frame(maxWidth: .infinity)
                        .frame(height: 112)
                }
            }
        case .threePanels:
            VStack(spacing: 8) {
                storyboardPhotoPanel(index: 0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 192)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 1)
                    storyboardPhotoPanel(index: 2)
                }
                .frame(height: 148)
            }
        case .threeVerticalPanels:
            HStack(spacing: 8) {
                storyboardPhotoPanel(index: 0)
                storyboardPhotoPanel(index: 1)
                storyboardPhotoPanel(index: 2)
            }
            .frame(height: 340)
        case .fourSquares:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 0)
                    storyboardPhotoPanel(index: 1)
                }
                .frame(height: 170)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 2)
                    storyboardPhotoPanel(index: 3)
                }
                .frame(height: 170)
            }
        case .fourVerticalPanels:
            HStack(spacing: 8) {
                storyboardPhotoPanel(index: 0)
                storyboardPhotoPanel(index: 1)
                storyboardPhotoPanel(index: 2)
                storyboardPhotoPanel(index: 3)
            }
            .frame(height: 340)
        case .fourHorizontalRectangles:
            VStack(spacing: 8) {
                ForEach(0..<layout.panelCount, id: \.self) { index in
                    storyboardPhotoPanel(index: index)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                }
            }
        case .fiveHorizontalPanels:
            VStack(spacing: 8) {
                ForEach(0..<layout.panelCount, id: \.self) { index in
                    storyboardPhotoPanel(index: index)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                }
            }
        case .fiveClassic:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 0)
                    storyboardPhotoPanel(index: 1)
                }
                .frame(height: 132)

                storyboardPhotoPanel(index: 2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 106)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 3)
                    storyboardPhotoPanel(index: 4)
                }
                .frame(height: 108)
            }
        case .sixSquares:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 0)
                    storyboardPhotoPanel(index: 1)
                }
                .aspectRatio(2, contentMode: .fit)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 2)
                    storyboardPhotoPanel(index: 3)
                }
                .aspectRatio(2, contentMode: .fit)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 4)
                    storyboardPhotoPanel(index: 5)
                }
                .aspectRatio(2, contentMode: .fit)
            }
        }
    }

    private func storyboardPhotoPanel(index: Int) -> some View {
        StoryboardPhotoPanel(
            image: storyboardPhotos.indices.contains(index) ? storyboardPhotos[index] : nil,
            placeholderImageName: "storyboard_placeholder_\(min(index + 1, 5))",
            number: index + 1
        )
    }

    private var nextAvailablePhotoSlot: Int? {
        storyboardPhotos.firstIndex(where: { $0 == nil })
    }

    private func setStoryboardPhoto(_ image: UIImage) {
        guard let slot = selectedPhotoSlot ?? nextAvailablePhotoSlot else {
            return
        }

        storyboardPhotos[slot] = image
        selectedPhotoSlot = nil
    }

    private func setStoryboardPhotos(_ images: [UIImage]) {
        guard
            !images.isEmpty,
            let firstSlot = selectedPhotoSlot ?? nextAvailablePhotoSlot
        else {
            selectedPhotoSlot = nil
            return
        }

        var updatedPhotos = storyboardPhotos
        var slot = firstSlot

        for image in images {
            guard updatedPhotos.indices.contains(slot) else {
                break
            }

            updatedPhotos[slot] = image
            slot += 1
        }

        storyboardPhotos = updatedPhotos
        selectedPhotoSlot = nil
    }

    @MainActor
    private func loadPhotoLibraryImages(from items: [PhotosPickerItem]) async {
        defer {
            selectedPhotoPickerItems = []
        }

        var images: [UIImage] = []

        for item in items {
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                continue
            }

            images.append(image)
        }

        setStoryboardPhotos(images)
    }

    private func removeStoryboardPhoto(at index: Int) {
        var existingPhotos = storyboardPhotos.compactMap { $0 }
        guard existingPhotos.indices.contains(index) else {
            return
        }

        existingPhotos.remove(at: index)
        storyboardPhotos = paddedStoryboardPhotos(existingPhotos)
    }

    private func paddedStoryboardPhotos(_ photos: [UIImage]) -> [UIImage?] {
        let trimmedPhotos = Array(photos.prefix(storyboardPhotos.count))
        return trimmedPhotos.map(Optional.some) + Array(repeating: nil, count: max(0, storyboardPhotos.count - trimmedPhotos.count))
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                NotebookPaperBackground(showsPaperWash: false, firstRuledLineY: 56)

                VStack(alignment: .leading, spacing: 14) {
                    TextField(
                        "",
                        text: $storyTitle,
                        prompt: Text("This is the title of your story")
                            .foregroundColor(Color.storyGray.opacity(0.46))
                    )
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(storyTitle.isEmpty ? Color.storyGray.opacity(0.46) : Color.storyInk)
                    .focused($isTitleFocused)
                    .textFieldStyle(.plain)
                    .submitLabel(.next)
                    .onSubmit {
                        isEditorFocused = true
                    }

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $entryText)
                            .font(.system(size: 16, weight: .regular))
                            .lineSpacing(7)
                            .foregroundStyle(Color.storyInk.opacity(0.78))
                            .scrollContentBackground(.hidden)
                            .scrollIndicators(.visible, axes: .vertical)
                            .background(Color.clear)
                            .focused($isEditorFocused)
                            .padding(.horizontal, -5)
                            .padding(.vertical, -7)
                            .padding(.top, 7)
                            .padding(.bottom, 28)
                            .onTapGesture {
                                isEditorFocused = true
                            }

                        if entryText.isEmpty {
                            Text("Today was...")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.storyGray.opacity(0.46))
                                .padding(.top, 15)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.leading, 54)
                .padding(.trailing, 18)
                .padding(.top, 14)
                .padding(.bottom, 18)
            }
            .frame(height: 504)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                HStack {
                    Rectangle()
                        .fill(Color.storyBorder.opacity(0.72))
                        .frame(width: 1)

                    Spacer()

                    Rectangle()
                        .fill(Color.storyBorder.opacity(0.72))
                        .frame(width: 1)
                }
            )
            .overlay(alignment: .bottomTrailing) {
                Button {
                    dismissKeyboard()
                    isShowingExpandedEditor = true
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.storyPurple)
                        .frame(width: 34, height: 34)
                        .background(Color.storyPurple.opacity(0.1), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.storyPurple.opacity(0.26), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open writing page")
                .padding(8)
            }
            .padding(.horizontal, -28)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private var storyDetailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Story Details")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)

            storyTextFieldRow(
                icon: "pencil",
                title: "Title",
                placeholder: "Give your story a title",
                text: $storyTitle
            )

            Divider()
                .padding(.leading, 44)

            storyTextFieldRow(
                icon: "location",
                title: "Location",
                placeholder: "Add a location",
                text: $storyLocation
            )

            Divider()
                .padding(.leading, 44)

            DatePicker(selection: $storyDate, displayedComponents: [.date, .hourAndMinute]) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.storyPurple)
                        .frame(width: 20)

                    Text("Date/time")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.storyInk.opacity(0.9))
                }
            }
            .font(.system(size: 13, weight: .medium))
            .tint(Color.storyPurple)
            .padding(.horizontal, 12)
            .frame(height: 48)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }

    private func storyTextFieldRow(
        icon: String,
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.storyPurple)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.storyInk.opacity(0.9))
                .frame(width: 72, alignment: .leading)

            TextField(placeholder, text: text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.storyInk)
                .tint(Color.storyPurple)
                .textInputAutocapitalization(.words)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
    }

    private var entryPrivacyCard: some View {
        VStack(spacing: 0) {
            entrySwitchRow(
                icon: "tray.and.arrow.down",
                title: "Save as Draft",
                subtitle: "Save progress and come back later",
                isOn: $savesDraft
            )

            Divider()
                .padding(.leading, 44)

            entrySwitchRow(
                icon: "lock.shield",
                title: "Private Entry",
                subtitle: "Only you can see this entry",
                isOn: $isPrivateEntry
            )
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }

    private func entrySwitchRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.storyPurple)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.storyInk)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.storyPurple))
        .padding(.horizontal, 12)
        .frame(height: 58)
    }

    private var artStylePickerSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center) {
                Text("Choose Art Style")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Button {
                    dismissKeyboard()
                    isShowingArtStyleGrid = true
                } label: {
                    Text("View all")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.storyPurple)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(artStyles, id: \.self) { style in
                        Button {
                            selectedArtStyle = style
                            dismissKeyboard()
                        } label: {
                            InlineArtStyleOption(
                                title: style,
                                isSelected: selectedArtStyle == style
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.54), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private var generateStoryboardButton: some View {
        Button {
            dismissKeyboard()
            startStoryboardGeneration()
        } label: {
            HStack(spacing: 7) {
                if isGeneratingStoryboard {
                    ProgressView()
                        .tint(.white)

                    Text("Generating...")
                } else {
                    Text("Generate Storyboard")
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color.storyPurple.opacity(0.95), Color.storyPurple],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .shadow(color: Color.storyPurple.opacity(0.18), radius: 10, y: 5)
        }
        .padding(.top, 2)
        .disabled(isGeneratingStoryboard)
        .opacity(isGeneratingStoryboard ? 0.76 : 1)
    }
}

struct ExpandedEntryEditor: View {
    @Binding var entryText: String

    @FocusState private var isFocused: Bool

    var body: some View {
        notebookPage
            .ignoresSafeArea()
            .navigationTitle("Write about this storyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(Color.homePageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                isFocused = true
            }
    }

    private var notebookPage: some View {
        ZStack(alignment: .topLeading) {
            NotebookPaperBackground()

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Write about this storyboard")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundStyle(Color.storyInk)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.homeMutedText.opacity(0.78))
                    }

                    Spacer(minLength: 12)
                }
                .padding(.leading, 54)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $entryText)
                        .font(.system(size: 16, weight: .regular))
                        .lineSpacing(7)
                        .foregroundStyle(Color.storyInk.opacity(0.78))
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.visible, axes: .vertical)
                        .scrollDismissesKeyboard(.interactively)
                        .background(Color.clear)
                        .tint(Color.storyPurple)
                        .focused($isFocused)
                        .padding(.horizontal, -5)
                        .padding(.vertical, -7)
                        .padding(.top, 7)

                    if entryText.isEmpty {
                        Text("Start writing...")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.storyGray.opacity(0.46))
                            .padding(.top, 15)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.leading, 54)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.72), lineWidth: 1)
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    isFocused = false
                }
                .font(.system(size: 14, weight: .bold))
            }
        }
    }
}

struct NotebookPaperBackground: View {
    private let paperColor = Color.homePageBackground
    var showsPaperWash = true
    var firstRuledLineY: CGFloat = 135

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                paperColor

                if showsPaperWash {
                    LinearGradient(
                        colors: [
                            .white.opacity(0.34),
                            .clear,
                            Color.storyGold.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                ruledLines(in: proxy.size)

                Rectangle()
                    .fill(Color.storyRose.opacity(0.52))
                    .frame(width: 1.2)
                    .padding(.leading, 54)

                pageHoles
                    .padding(.leading, 20)
                    .padding(.top, 92)
            }
        }
    }

    private func ruledLines(in size: CGSize) -> some View {
        Path { path in
            var y = firstRuledLineY
            while y < size.height - 18 {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += 35
            }
        }
        .stroke(Color(red: 0.45, green: 0.58, blue: 0.78).opacity(0.24), lineWidth: 1)
    }

    private var pageHoles: some View {
        VStack(spacing: 96) {
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.82))
                    .frame(width: 13, height: 13)
                    .overlay(
                        Circle()
                            .stroke(Color.storyBorder.opacity(0.32), lineWidth: 1)
                    )
            }
        }
    }
}

struct ArtStyleGridSheet: View {
    let artStyles: [String]

    @Binding var selectedArtStyle: String

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Choose art style")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.storyPurple)
                        .frame(height: 38)
                }
            }

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(artStyles, id: \.self) { style in
                        Button {
                            selectedArtStyle = style
                        } label: {
                            ArtStyleGridOption(
                                title: style,
                                isSelected: selectedArtStyle == style
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 18)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .background(Color.homePageBackground)
    }
}

struct ArtStyleGridOption: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 7) {
            GeometryReader { proxy in
                ZStack(alignment: .topTrailing) {
                    Image(artStyleAssetName(for: title))
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.width)
                        .clipped()

                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(isSelected ? Color.storyPurple : Color.storyBorder.opacity(0.5), lineWidth: isSelected ? 2.5 : 1)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white, Color.storyPurple)
                            .padding(7)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .aspectRatio(1, contentMode: .fit)

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

struct StoryboardPhotoStripThumbnail: View {
    let image: UIImage
    let removeAction: () -> Void

    private let size: CGFloat = 64
    private let bottomPadding: CGFloat = 16

    var body: some View {
        ZStack(alignment: .topTrailing) {

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white)
                .frame(width: size, height: size + bottomPadding)
                .shadow(color: .black.opacity(0.13), radius: 5, x: 0, y: 3)

            VStack(spacing: 0) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size - 10, height: size - 10)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.storyInk.opacity(0.45), lineWidth: 0.8)
                    )
                    .padding(.top, 5)

                Spacer(minLength: 0)
            }
            .frame(width: size, height: size + bottomPadding)

            Button {
                removeAction()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 17, height: 17)
                    .background(Color.black.opacity(0.58), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(3)
        }
        .frame(width: size, height: size + bottomPadding)
    }
}

struct StoryboardPhotoStripAddButton: View {
    var body: some View {
        VStack {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.storyInk.opacity(0.82))
        }
        .frame(width: 56, height: 56)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.storyPurple.opacity(0.34), style: StrokeStyle(lineWidth: 1.1, dash: [4, 3]))
        )
        .accessibilityLabel("Add photos")
    }
}

struct StoryboardPhotoDropDelegate: DropDelegate {
    @Binding var photos: [UIImage?]
    @Binding var draggedIndex: Int?

    let destinationIndex: Int

    func dropEntered(info: DropInfo) {
        guard
            let draggedIndex,
            draggedIndex != destinationIndex
        else {
            return
        }

        var compactPhotos = photos.compactMap { $0 }
        guard
            compactPhotos.indices.contains(draggedIndex),
            compactPhotos.indices.contains(destinationIndex)
        else {
            return
        }

        let photo = compactPhotos.remove(at: draggedIndex)
        compactPhotos.insert(photo, at: destinationIndex)
        photos = compactPhotos.map(Optional.some) + Array(repeating: nil, count: max(0, photos.count - compactPhotos.count))
        self.draggedIndex = destinationIndex
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedIndex = nil
        return true
    }
}

struct StoryboardPhotoPanel: View {
    let image: UIImage?
    let placeholderImageName: String
    let number: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)

            GeometryReader { proxy in
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                    } else {
                        Image(placeholderImageName)
                            .resizable()
                    }
                }
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }

            if image == nil {
                Rectangle()
                    .fill(Color.white.opacity(0.34))
            }

            Text("\(number)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.storyPurple)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.82), in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.storyPurple.opacity(0.22), lineWidth: 1)
                )
        }
        .overlay(
            Rectangle()
                .stroke(Color.storyInk.opacity(0.88), lineWidth: 1.5)
        )
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

struct CameraPhotoPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            dismiss: dismiss,
            onImagePicked: onImagePicked
        )
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let dismiss: DismissAction
        private let onImagePicked: (UIImage) -> Void

        init(
            dismiss: DismissAction,
            onImagePicked: @escaping (UIImage) -> Void
        ) {
            self.dismiss = dismiss
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }

            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

struct InlineArtStyleOption: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            Image(inlineArtStyleAssetName(for: title))
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.storyPurple : Color.storyBorder.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white, Color.storyPurple)
                            .padding(5)
                    }
                }

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 76)
        }
    }
}

func inlineArtStyleAssetName(for title: String) -> String {
    switch title {
    case "Anime":
        return "inline_art_style_anime"
    case "Graphic Novel":
        return "inline_art_style_graphic_novel"
    case "Pixel Art":
        return "inline_art_style_pixel_art"
    case "Manga":
        return "inline_art_style_manga"
    case "Cozy Storybook":
        return "inline_art_style_cozy_storybook"
    case "Pop Art":
        return "inline_art_style_pop_art"
    case "Colored Journal":
        return "inline_art_style_colored_journal"
    default:
        return "inline_art_style_anime"
    }
}

func artStylePromptDescription(for title: String) -> String {
switch title {

    case "Anime":
        return """
        Authentic modern anime artwork. Strongly stylized anime characters with large expressive eyes, simplified facial features, clean cel shading, vibrant colors, dramatic lighting, and dynamic poses.
        NOT photorealistic.
        Preserve identity but reinterpret all people as anime characters. Do not preserve realistic skin textures, facial proportions, or photographic details.
        The final result should look like a frame from a high-budget anime series, not a photograph with anime effects applied.
        """

    case "Graphic Novel":
        return """
        Premium western graphic novel artwork. Bold ink outlines, dramatic shadows, cinematic composition, painterly rendering, graphic shapes, and highly stylized comic-book storytelling.
        NOT photorealistic.
        Characters should look illustrated and artist-rendered rather than realistic. Use strong visual stylization, dramatic contrast, and graphic novel energy.
        The final result should look like published graphic novel artwork, not a painted photograph.
        """

    case "Pixel Art":
        return """
        Authentic 16-bit pixel art video game artwork. Large visible pixels, pixel-perfect edges, limited color palette, sprite-like characters, retro RPG environments, and deliberate pixel construction throughout.
        ABSOLUTELY NO smooth illustration or photorealistic rendering.
        Every object, character, and background element must be visibly pixelated.
        The final image should look like a premium SNES-era RPG screenshot, not a normal illustration with a pixel filter.
        """

    case "Manga":
        return """
        Authentic Japanese manga artwork. Highly stylized manga characters with expressive eyes, exaggerated expressions, bold black inks, screentones, cross-hatching, speed lines, dramatic camera angles, and dynamic manga storytelling.
        NOT photorealistic.
        Preserve identity but transform all people into manga characters. Simplify facial features and strongly stylize proportions.
        The final result should look like pages from a published manga series, not a realistic black-and-white photograph.
        """

    case "Cozy Storybook":
        return """
        Whimsical storybook illustration. Hand-painted watercolor and gouache textures, warm colors, soft edges, charming character designs, dreamy environments, and magical storybook atmosphere.
        NOT photorealistic.
        Characters should feel illustrated, charming, and slightly idealized rather than realistic.
        The final result should look like artwork from a beautifully illustrated children's storybook.
        """

    case "Pop Art":
        return """
        Bold pop art comic artwork inspired by classic comic books and gallery pop art. Thick black outlines, flat saturated colors, strong graphic shapes, Ben-Day dots, poster-like composition, and exaggerated visual impact.
        NOT photorealistic.
        Simplify forms into graphic comic-book shapes and bold color blocks.
        The final result should look like authentic pop art illustration, not a photo with color effects.
        """

    case "Colored Journal":
        return """
        Hand-drawn illustrated journal artwork. Loose sketch lines, colored pencil textures, marker rendering, handwritten sketchbook energy, personal diary charm, and expressive imperfect drawing.
        NOT photorealistic.
        Everything should feel hand-drawn by an artist in a personal journal. Visible sketch lines, artistic imperfections, and traditional drawing textures are encouraged.
        The final result should look like illustrated journal pages, not realistic digital artwork.
        """

    default:
        return """
        Fully commit to the selected art style.
        Preserve identity but not realism.
        Reinterpret everything as stylized artwork rather than photography.
        """
    }   
}

func artStyleAssetName(for title: String) -> String {
    switch title {
    case "Anime":
        return "art_style_anime"
    case "Graphic Novel":
        return "art_style_graphic_novel"
    case "Pixel Art":
        return "art_style_pixel_art"
    case "Manga":
        return "art_style_manga"
    case "Cozy Storybook":
        return "art_style_cozy_storybook"
    case "Pop Art":
        return "art_style_pop_art"
    case "Colored Journal":
        return "art_style_colored_journal"
    default:
        return "art_style_anime"
    }
}

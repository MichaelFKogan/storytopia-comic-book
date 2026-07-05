import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum CreateEntryDestination {
    case daily
    case custom
}

private struct LoadedCreateEntryDraftSnapshot: Equatable {
    let id: UUID
    let title: String
    let text: String
    let photoIDs: [ObjectIdentifier]
    let artStyle: String
    let location: String
    let date: Date
    let savesDraft: Bool
    let isPrivate: Bool
    let fontChoiceRawValue: String?
    let textColorIndex: Int
    let textSize: Double
    let paperStyleRawValue: String
    let paperColorIndex: Int

    init(
        id: UUID,
        title: String,
        text: String,
        photos: [UIImage],
        artStyle: String,
        location: String,
        date: Date,
        savesDraft: Bool,
        isPrivate: Bool,
        fontChoiceRawValue: String?,
        textColorIndex: Int,
        textSize: Double,
        paperStyleRawValue: String,
        paperColorIndex: Int
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.photoIDs = photos.map { ObjectIdentifier($0) }
        self.artStyle = artStyle
        self.location = location
        self.date = date
        self.savesDraft = savesDraft
        self.isPrivate = isPrivate
        self.fontChoiceRawValue = fontChoiceRawValue
        self.textColorIndex = textColorIndex
        self.textSize = textSize
        self.paperStyleRawValue = paperStyleRawValue
        self.paperColorIndex = paperColorIndex
    }
}

private enum CreateTextAlignmentChoice: String, CaseIterable, Identifiable {
    case leading
    case center
    case trailing

    var id: String { rawValue }

    var textAlignment: NSTextAlignment {
        switch self {
        case .leading:
            .left
        case .center:
            .center
        case .trailing:
            .right
        }
    }

    var systemName: String {
        switch self {
        case .leading:
            "text.alignleft"
        case .center:
            "text.aligncenter"
        case .trailing:
            "text.alignright"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .leading:
            "Align text left"
        case .center:
            "Align text center"
        case .trailing:
            "Align text right"
        }
    }

    var next: CreateTextAlignmentChoice {
        switch self {
        case .leading:
            .center
        case .center:
            .trailing
        case .trailing:
            .leading
        }
    }
}

private enum CreateFormattingTab: String, CaseIterable, Identifiable {
    case fontStyle
    case paperStyle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fontStyle:
            "Font Style"
        case .paperStyle:
            "Paper Style"
        }
    }

    var symbol: String {
        switch self {
        case .fontStyle:
            "textformat"
        case .paperStyle:
            "doc"
        }
    }
}

private enum CreateFontChoice: String, CaseIterable, Identifiable {
    case sans
    case serif
    case nunito
    case lora
    case crimsonPro
    case caveat
    case patrickHand
    case gloriaHallelujah
    case permanentMarker
    case specialElite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sans:
            "Sans"
        case .serif:
            "Serif"
        case .nunito:
            "Nunito"
        case .lora:
            "Lora"
        case .crimsonPro:
            "Crimson Pro"
        case .caveat:
            "Caveat"
        case .patrickHand:
            "Patrick Hand"
        case .gloriaHallelujah:
            "Gloria"
        case .permanentMarker:
            "Marker"
        case .specialElite:
            "Typewriter"
        }
    }

    var design: Font.Design {
        switch self {
        case .serif, .lora, .crimsonPro:
            .serif
        case .sans, .nunito:
            .default
        case .caveat, .patrickHand, .gloriaHallelujah, .permanentMarker:
            .rounded
        case .specialElite:
            .monospaced
        }
    }

    var uiKitDesign: UIFontDescriptor.SystemDesign {
        switch self {
        case .serif, .lora, .crimsonPro:
            .serif
        case .sans, .nunito:
            .default
        case .caveat, .patrickHand, .gloriaHallelujah, .permanentMarker:
            .rounded
        case .specialElite:
            .monospaced
        }
    }

    var fontName: String? {
        switch self {
        case .sans, .serif:
            nil
        case .nunito:
            "Nunito"
        case .lora:
            "Lora-Regular"
        case .crimsonPro:
            "CrimsonPro-Regular"
        case .caveat:
            "Caveat-Regular"
        case .patrickHand:
            "PatrickHand-Regular"
        case .gloriaHallelujah:
            "GloriaHallelujah"
        case .permanentMarker:
            "PermanentMarker-Regular"
        case .specialElite:
            "SpecialElite-Regular"
        }
    }

    var usesVariableWeight: Bool {
        switch self {
        case .nunito, .lora, .crimsonPro, .caveat:
            true
        default:
            false
        }
    }

    var bodyWeight: Font.Weight {
        switch self {
        case .nunito, .lora, .caveat:
            .bold
        case .crimsonPro:
            .semibold
        case .patrickHand, .gloriaHallelujah, .permanentMarker, .specialElite:
            .regular
        default:
            .medium
        }
    }

    /// Direct wght-axis values for variable fonts that need tuning beyond `bodyWeight`.
    var bodyWght: CGFloat? {
        switch self {
        case .nunito:
            700
        case .caveat:
            700
        default:
            nil
        }
    }

    /// Compensates for fonts that render smaller at the same point size.
    var bodySizeScale: CGFloat {
        switch self {
        case .crimsonPro:
            1.18
        case .patrickHand:
            1.18
        case .caveat:
            1.28
        default:
            1
        }
    }

    static func savedValue(_ rawValue: String?) -> CreateFontChoice {
        guard let rawValue else {
            return .sans
        }

        switch rawValue {
        case "handwritten":
            return .patrickHand
        case "typewriter":
            return .specialElite
        default:
            return CreateFontChoice(rawValue: rawValue) ?? .nunito
        }
    }

    func swiftUIFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard let fontName else {
            return .system(size: size, weight: weight, design: design)
        }

        return VariableFont.font(
            name: fontName,
            size: size,
            weight: weight,
            usesWeightAxis: usesVariableWeight
        )
    }

    func swiftUIBodyFont(size: CGFloat) -> Font {
        guard let fontName else {
            return .system(size: size * bodySizeScale, weight: bodyWeight, design: design)
        }

        return VariableFont.font(
            name: fontName,
            size: size * bodySizeScale,
            weight: bodyWeight,
            usesWeightAxis: usesVariableWeight,
            wghtOverride: bodyWght
        )
    }
}

fileprivate enum CreatePaperStyleChoice: String, CaseIterable, Identifiable {
    case collegeRuled
    case blank
    case watercolorPaper
    case cottonPaper
    case recycledPaper

    var id: String { rawValue }

    var title: String {
        switch self {
        case .collegeRuled:
            "College Ruled"
        case .blank:
            "Blank"
        case .watercolorPaper:
            "Watercolor Paper"
        case .cottonPaper:
            "Cotton Paper"
        case .recycledPaper:
            "Recycled Paper"
        }
    }

    var showsRuledLines: Bool {
        self == .collegeRuled
    }

    var showsNotebookChrome: Bool {
        self == .collegeRuled
    }

    var showsPaperColorOptions: Bool {
        backgroundImageName == nil
    }

    var usesTexturedPaperTextEffect: Bool {
        backgroundImageName != nil
    }

    var backgroundImageName: String? {
        switch self {
        case .watercolorPaper:
            "watercolor-paper"
        case .cottonPaper:
            "cotton-paper"
        case .recycledPaper:
            "recycled-paper"
        case .collegeRuled, .blank:
            nil
        }
    }

    var leadingContentPadding: CGFloat {
        switch self {
        case .collegeRuled:
            NotebookMetrics.marginLeading
        case .blank, .watercolorPaper, .cottonPaper, .recycledPaper:
            18
        }
    }

    var leadingTextPadding: CGFloat {
        switch self {
        case .collegeRuled:
            NotebookMetrics.textLeadingInset
        case .blank, .watercolorPaper, .cottonPaper, .recycledPaper:
            0
        }
    }
}

private struct CreateColorOption {
    let color: Color
    let uiColor: UIColor
}

private enum CreateFormattingPalette {
    static let textColors: [CreateColorOption] = [
        CreateColorOption(color: .black, uiColor: .black),
        CreateColorOption(color: Color(red: 0.27, green: 0.31, blue: 0.42), uiColor: UIColor(red: 0.27, green: 0.31, blue: 0.42, alpha: 1)),
        CreateColorOption(color: Color(red: 0.08, green: 0.19, blue: 0.34), uiColor: UIColor(red: 0.08, green: 0.19, blue: 0.34, alpha: 1)),
        CreateColorOption(color: Color(red: 0.20, green: 0.45, blue: 0.72), uiColor: UIColor(red: 0.20, green: 0.45, blue: 0.72, alpha: 1)),
        CreateColorOption(color: Color(red: 0.10, green: 0.30, blue: 0.28), uiColor: UIColor(red: 0.10, green: 0.30, blue: 0.28, alpha: 1)),
        CreateColorOption(color: Color(red: 0.29, green: 0.18, blue: 0.47), uiColor: UIColor(red: 0.29, green: 0.18, blue: 0.47, alpha: 1)),
        CreateColorOption(color: Color(red: 0.46, green: 0.16, blue: 0.27), uiColor: UIColor(red: 0.46, green: 0.16, blue: 0.27, alpha: 1)),
        CreateColorOption(color: Color(red: 0.34, green: 0.20, blue: 0.17), uiColor: UIColor(red: 0.34, green: 0.20, blue: 0.17, alpha: 1)),
        CreateColorOption(color: Color(red: 0.55, green: 0.34, blue: 0.10), uiColor: UIColor(red: 0.55, green: 0.34, blue: 0.10, alpha: 1)),
        CreateColorOption(color: Color(red: 0.42, green: 0.42, blue: 0.49), uiColor: UIColor(red: 0.42, green: 0.42, blue: 0.49, alpha: 1))
    ]

    static let paperColors: [Color] = [
        Color.white,
        .homePageBackground,
        Color(red: 0.98, green: 0.93, blue: 0.86),
        Color(red: 1.0, green: 0.95, blue: 0.75),
        Color(red: 0.86, green: 0.93, blue: 0.97),
        Color(red: 0.86, green: 0.94, blue: 0.86),
        Color(red: 0.88, green: 0.83, blue: 0.95)
    ]
}

@MainActor
enum DraftThumbnailRenderer {
    static func render(
        title: String,
        text: String,
        photos: [UIImage],
        fontChoiceRawValue: String?,
        textColorIndex: Int?,
        textSize: Double?,
        paperStyleRawValue: String?,
        paperColorIndex: Int?,
        isBold: Bool = false,
        isItalic: Bool = false,
        isUnderlined: Bool = false,
        isStrikethrough: Bool = false,
        isHighlighted: Bool = false,
        textAlignmentRawValue: String = CreateTextAlignmentChoice.leading.rawValue
    ) -> UIImage? {
        let fontChoice = CreateFontChoice.savedValue(fontChoiceRawValue)
        let normalizedTextColorIndex = min(max(textColorIndex ?? 0, 0), CreateFormattingPalette.textColors.count - 1)
        let normalizedTextSize = min(max(textSize ?? 0.36, 0), 1)
        let paperStyle = paperStyleRawValue.flatMap(CreatePaperStyleChoice.init(rawValue:)) ?? .collegeRuled
        let normalizedPaperColorIndex = min(max(paperColorIndex ?? 0, 0), CreateFormattingPalette.paperColors.count - 1)
        let paperColor = CreateFormattingPalette.paperColors[normalizedPaperColorIndex]
        let textColor = CreateFormattingPalette.textColors[normalizedTextColorIndex].color
        let textAlignment = CreateTextAlignmentChoice(rawValue: textAlignmentRawValue) ?? .leading

        let thumbnailSize = CGSize(width: 260, height: 340)
        let thumbnail = DraftPageThumbnail(
            title: title,
            text: text,
            photos: Array(photos.prefix(2)),
            fontChoice: fontChoice,
            textColor: textColor,
            textSize: CGFloat(14 + normalizedTextSize * 8),
            paperStyle: paperStyle,
            paperColor: paperStyle.showsPaperColorOptions ? paperColor : .homePageBackground,
            isBold: isBold,
            isItalic: isItalic,
            isUnderlined: isUnderlined,
            isStrikethrough: isStrikethrough,
            isHighlighted: isHighlighted,
            textAlignment: textAlignment
        )
        .frame(width: thumbnailSize.width, height: thumbnailSize.height)

        let renderer = ImageRenderer(content: thumbnail)
        renderer.proposedSize = ProposedViewSize(width: thumbnailSize.width, height: thumbnailSize.height)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

private struct DraftPageThumbnail: View {
    let title: String
    let text: String
    let photos: [UIImage]
    let fontChoice: CreateFontChoice
    let textColor: Color
    let textSize: CGFloat
    let paperStyle: CreatePaperStyleChoice
    let paperColor: Color
    let isBold: Bool
    let isItalic: Bool
    let isUnderlined: Bool
    let isStrikethrough: Bool
    let isHighlighted: Bool
    let textAlignment: CreateTextAlignmentChoice

    private var displayTitle: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "Untitled Entry" : trimmedTitle
    }

    private var displayText: String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? "Start writing..." : trimmedText
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            NotebookPaperBackground(
                paperColor: paperStyle.backgroundImageName == nil ? paperColor : .homePageBackground,
                paperImageName: paperStyle.backgroundImageName,
                showsPaperWash: false,
                showsRuledLines: paperStyle.showsRuledLines,
                showsNotebookChrome: paperStyle.showsNotebookChrome,
                firstRuledLineY: 84
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(displayTitle)
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(2)

                if !photos.isEmpty {
                    HStack(spacing: 7) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { _, photo in
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 74)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                    }
                }

                Text(displayText)
                    .font(isItalic ? fontChoice.swiftUIBodyFont(size: min(textSize, 19)).italic() : fontChoice.swiftUIBodyFont(size: min(textSize, 19)))
                    .fontWeight(isBold ? .bold : .regular)
                    .underline(isUnderlined)
                    .strikethrough(isStrikethrough)
                    .foregroundStyle(textColor)
                    .padding(.horizontal, isHighlighted ? 3 : 0)
                    .background(isHighlighted ? Color.yellow.opacity(0.26) : Color.clear)
                    .multilineTextAlignment(textAlignment == .center ? .center : textAlignment == .trailing ? .trailing : .leading)
                    .lineSpacing(4)
                    .lineLimit(10)
            }
            .padding(.top, 28)
            .padding(.trailing, 18)
            .padding(.bottom, 20)
            .padding(.leading, paperStyle.leadingContentPadding)
        }
        .background(paperStyle.backgroundImageName == nil ? paperColor : Color.homePageBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.42), lineWidth: 1)
        )
    }
}

struct CreateEntryView: View {
    private let artStyles = ["Anime", "Graphic Novel", "Pixel Art", "Manga", "Cozy Storybook", "Pop Art", "Colored Journal"]

    @Binding var entryText: String
    @Binding var storyTitle: String
    @Binding var storyboardPhotos: [UIImage?]
    @Binding var isDraftSaved: Bool
    @Binding var activeDraftID: UUID?
    @Binding var selectedPage: StoryPage
    @Binding var generatedStoryboards: [GeneratedStoryboard]
    let dismissCreate: () -> Void

    @State private var selectedArtStyle = "Anime"
    private let previewLayout = StoryboardLayoutOption.fiveClassic

    @State private var selectedPhotoSlot: Int?
    @State private var isShowingPhotoSourceDialog = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingCamera = false
    @State private var isShowingExitConfirmation = false
    @State private var isGeneratingStoryboard = false
    @State private var generationErrorMessage: String?
    @State private var isFullScreenEditorVisible = false
    @State private var isShowingArtStyleGrid = false
    @State private var isShowingFormattingSheet = false
    @State private var isShowingJournalDestinationSheet = false
    @State private var selectedFormattingTab: CreateFormattingTab = .fontStyle
    @State private var selectedFontChoice: CreateFontChoice = .sans
    @State private var selectedPaperStyleChoice: CreatePaperStyleChoice = .collegeRuled
    @State private var selectedTextColorIndex = 0
    @State private var selectedPaperColorIndex = 0
    @State private var previewTextSize: Double = 0.36
    @State private var textFormattingRequestID = 0
    @State private var textFormattingRequest: NotebookTextFormattingRequest?
    @State private var entryDestination: CreateEntryDestination = .daily
    @State private var selectedCustomJournalTitle: String?
    @State private var addedJournalTitle: String?
    @State private var storyLocation = ""
    @State private var storyDate = Date()
    @State private var savesDraft = true
    @State private var isPrivateEntry = false
    @State private var selectedPhotoPickerItems: [PhotosPickerItem] = []
    @State private var draggedStoryboardPhotoIndex: Int?
    @State private var isShowingEntryOptionsPage = false
    @State private var loadedDraftSnapshot: LoadedCreateEntryDraftSnapshot?
    @GestureState private var exitDragOffset: CGFloat = 0
    @FocusState private var isTitleFocused: Bool
    @State private var editorFocusRequestID = 0
    @State private var editorBlurRequestID = 0
    @State private var isKeyboardVisible = false

    private func dismissKeyboard() {
        isTitleFocused = false
        editorBlurRequestID += 1
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func showEntryOptionsPage() {
        dismissKeyboard()
        isShowingEntryOptionsPage = true
    }

    private var selectedTextStyle: NotebookTextStyle {
        let textColor = CreateFormattingPalette.textColors[
            min(max(selectedTextColorIndex, 0), CreateFormattingPalette.textColors.count - 1)
        ]

        return NotebookTextStyle(
            swiftUIDesign: selectedFontChoice.design,
            uiKitDesign: selectedFontChoice.uiKitDesign,
            customFontName: selectedFontChoice.fontName,
            customFontWeight: selectedFontChoice.bodyWeight,
            customFontWght: selectedFontChoice.bodyWght,
            customFontUsesVariableWeight: selectedFontChoice.usesVariableWeight,
            customFontSizeScale: selectedFontChoice.bodySizeScale,
            bodyFontSize: CGFloat(14 + previewTextSize * 8),
            color: textColor.color,
            uiColor: textColor.uiColor
        )
    }

    private var selectedPaperColor: Color {
        CreateFormattingPalette.paperColors[
            min(max(selectedPaperColorIndex, 0), CreateFormattingPalette.paperColors.count - 1)
        ]
    }

    private var selectedPageBackgroundColor: Color {
        selectedPaperStyleChoice.showsPaperColorOptions ? selectedPaperColor : .homePageBackground
    }

    private var selectedPaperSurfaceColor: Color {
        usesPaperImageBackground ? .clear : selectedPageBackgroundColor
    }

    private var usesPaperImageBackground: Bool {
        selectedPaperStyleChoice.backgroundImageName != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissKeyboard()
                    }

                layoutPage
            }
            .navigationDestination(isPresented: $isShowingEntryOptionsPage) {
                entryOptionsPage
            }
        }
        .offset(x: exitDragOffset)
        .simultaneousGesture(exitSwipeGesture)
        .animation(.snappy(duration: 0.22), value: exitDragOffset)
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
        .sheet(isPresented: $isShowingFormattingSheet) {
            CreateFormattingSheet(
                selectedTab: $selectedFormattingTab,
                selectedFont: $selectedFontChoice,
                selectedPaperStyle: $selectedPaperStyleChoice,
                selectedTextColorIndex: $selectedTextColorIndex,
                selectedPaperColorIndex: $selectedPaperColorIndex,
                previewTextSize: $previewTextSize
            )
            .presentationDetents([.height(430), .large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.homePageBackground)
        }
        .sheet(isPresented: $isShowingJournalDestinationSheet) {
            AddToJournalSheet(selectedJournalTitle: $selectedCustomJournalTitle) { journalTitle in
                selectedCustomJournalTitle = journalTitle
                entryDestination = .custom
                isShowingJournalDestinationSheet = false
            }
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
        .alert("Save this entry?", isPresented: $isShowingExitConfirmation) {
            Button("Save Entry") {
                saveDraftAndExit()
            }

            Button("Discard", role: .destructive) {
                discardDraftAndExit()
            }

            Button("Cancel", role: .cancel) {
            }
        } message: {
            Text("You’ve started an entry. Would you like to save it before leaving?")
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
        .alert(
            "Entry Added!",
            isPresented: Binding(
                get: { addedJournalTitle != nil },
                set: { isPresented in
                    if !isPresented {
                        addedJournalTitle = nil
                    }
                }
            )
        ) {
            Button("Continue Writing", role: .cancel) {
                addedJournalTitle = nil
            }

            Button("View Journal") {
                addedJournalTitle = nil
                selectedPage = .journal
            }
        } message: {
            Text("This entry is now part of \(addedJournalTitle ?? "your journal").")
        }
        .onChange(of: selectedPhotoPickerItems) { items in
            guard !items.isEmpty else {
                return
            }

            Task {
                await loadPhotoLibraryImages(from: items)
            }
        }
        .onAppear {
            loadSavedDraftIfNeeded()
        }
    }

    private func startStoryboardGeneration() {
        guard !isGeneratingStoryboard else {
            return
        }

        guard let journalTitle = selectedEntryJournalTitle else {
            isShowingJournalDestinationSheet = true
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
                    addCurrentEntry(to: journalTitle)
                    generatedStoryboards.insert(storyboard, at: 0)
                    GeneratedStoryboardStore.save(generatedStoryboards)
                    clearEditor()
                    if let activeDraftID {
                        CreateEntryDraftStore.delete(id: activeDraftID)
                    }
                    self.activeDraftID = nil
                    isDraftSaved = !CreateEntryDraftStore.loadAll().isEmpty
                    isGeneratingStoryboard = false
                    addedJournalTitle = entryDestination == .daily ? "Daily Journal" : journalTitle
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
            if isFullScreenEditorVisible {
                fullScreenEditorContent
            } else {
                createEntryContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(pageTapBackground)
            }
        }
        .background(selectedPaperSurfaceColor)
        .overlay(alignment: .bottomTrailing) {
            if !isKeyboardVisible {
                editorFloatingToolStack
                    .padding(.trailing, 31)
                    .padding(.bottom, editorFloatingToolBottomPadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isFullScreenEditorVisible {
                createToolbarItems(title: "Write Entry", showsCloseButton: true)
            }
        }
        .toolbar(isFullScreenEditorVisible ? .hidden : .visible, for: .navigationBar)
        .toolbarBackground(usesPaperImageBackground ? .hidden : .visible, for: .navigationBar)
        .toolbarBackground(selectedPageBackgroundColor, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            KeyboardCornerRadiusRemover.removeKeyboardCornerRadius()
            withAnimation(.snappy(duration: 0.22)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.snappy(duration: 0.22)) {
                isKeyboardVisible = false
            }
        }
    }

    private var entryOptionsPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            entryOptionsStepContent
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(pageTapBackground)
        }
        .background(Color.homePageBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            createToolbarItems(title: "Entry Details", showsCloseButton: false)
        }
        .toolbarBackground(Color.homePageBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var fullScreenEditorContent: some View {
        GeometryReader { proxy in
            let scrollContentHeight = editorScrollContentHeight(for: proxy.size.height)

            ScrollView {
                ZStack(alignment: .topLeading) {
                    NotebookPaperBackground(
                        paperColor: selectedPaperSurfaceColor,
                        paperImageName: selectedPaperStyleChoice.backgroundImageName,
                        showsPaperWash: false,
                        showsRuledLines: selectedPaperStyleChoice.showsRuledLines,
                        showsNotebookChrome: selectedPaperStyleChoice.showsNotebookChrome,
                        firstRuledLineY: NotebookMetrics.firstNotebookRuleY
                    )
                    .frame(maxWidth: .infinity, minHeight: scrollContentHeight, maxHeight: .infinity)

                    NotebookEditorContent(
                        storyTitle: $storyTitle,
                        entryText: $entryText,
                        isTitleFocused: $isTitleFocused,
                        editorFocusRequestID: editorFocusRequestID,
                        editorBlurRequestID: editorBlurRequestID,
                        formattingRequest: textFormattingRequest,
                        bodyPlaceholder: "Start writing...",
                        scrollsInternally: false,
                        pageHeight: scrollContentHeight,
                        textStyle: selectedTextStyle,
                        showsTitleRule: selectedPaperStyleChoice.showsNotebookChrome,
                        leadingContentPadding: selectedPaperStyleChoice.leadingContentPadding,
                        leadingTextPadding: selectedPaperStyleChoice.leadingTextPadding,
                        usesTexturedPaperEffect: selectedPaperStyleChoice.usesTexturedPaperTextEffect,
                        onBodyTap: {
                            isTitleFocused = false
                            editorFocusRequestID += 1
                        },
                        onTitleSubmit: {
                            editorFocusRequestID += 1
                        }
                    )
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: scrollContentHeight)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(selectedPaperSurfaceColor)
            .notebookPageChrome()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isKeyboardVisible {
                    fullScreenKeyboardBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.22), value: isKeyboardVisible)
        }
        .background(selectedPaperSurfaceColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fullScreenKeyboardBar: some View {
        HStack {
            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.22)) {
                    isFullScreenEditorVisible = false
                }
            } label: {
                editorFloatingToolIcon {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show Create controls")
        }
        .padding(.horizontal, 31)
        .padding(.vertical, 8)
    }

    private var pageTapBackground: some View {
        Color.homePageBackground.opacity(usesPaperImageBackground ? 0 : 1)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
    }

    @ViewBuilder
    private var pageBackground: some View {
        if let paperImageName = selectedPaperStyleChoice.backgroundImageName {
            GeometryReader { proxy in
                Image(paperImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
        } else {
            Color.homePageBackground
        }
    }

    @ToolbarContentBuilder
    private func createToolbarItems(title: String, showsCloseButton: Bool) -> some ToolbarContent {
        if showsCloseButton {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    requestExit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.storyInk.opacity(0.72))
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .hideSharedBackgroundIfAvailable()
        }

        ToolbarItem(placement: .principal) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(Color.storyGray.opacity(0.46))
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                saveDraftAndExit()
            } label: {
                Text("Save")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.storyPurple)
            }
            .buttonStyle(.plain)
        }
        .hideSharedBackgroundIfAvailable()
    }

    private var hasDraftContent: Bool {
        !storyTitle.isEmpty || !entryText.isEmpty || storyboardPhotos.contains { $0 != nil }
    }

    private var hasUnsavedDraftChanges: Bool {
        guard let loadedDraftSnapshot else {
            return hasDraftContent
        }

        return currentDraftSnapshot(id: loadedDraftSnapshot.id) != loadedDraftSnapshot
    }

    private var exitSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .updating($exitDragOffset) { value, state, _ in
                guard isExitSwipe(value) else {
                    return
                }

                state = value.translation.width
            }
            .onEnded { value in
                let shouldExit = value.translation.width > 96
                    || value.predictedEndTranslation.width > 180

                if shouldExit && isExitSwipe(value) {
                    requestExit()
                }
            }
    }

    private func isExitSwipe(_ value: DragGesture.Value) -> Bool {
        value.translation.width > 0
            && abs(value.translation.height) < max(24, value.translation.width * 0.65)
    }

    private func requestExit() {
        dismissKeyboard()

        if hasUnsavedDraftChanges {
            isShowingExitConfirmation = true
        } else {
            closeEditorWithoutSaving()
        }
    }

    private func closeEditorWithoutSaving() {
        dismissKeyboard()
        clearEditor()
        activeDraftID = nil
        isDraftSaved = !CreateEntryDraftStore.loadAll().isEmpty
        withAnimation(.snappy(duration: 0.32)) {
            dismissCreate()
        }
    }

    private func saveDraftAndExit() {
        dismissKeyboard()

        if hasDraftContent {
            let draftPhotos = storyboardPhotos.compactMap { $0 }
            let draftThumbnail = DraftThumbnailRenderer.render(
                title: storyTitle,
                text: entryText,
                photos: draftPhotos,
                fontChoiceRawValue: selectedFontChoice.rawValue,
                textColorIndex: selectedTextColorIndex,
                textSize: previewTextSize,
                paperStyleRawValue: selectedPaperStyleChoice.rawValue,
                paperColorIndex: selectedPaperColorIndex
            )

            _ = CreateEntryDraftStore.save(
                id: activeDraftID,
                title: storyTitle,
                text: entryText,
                photos: draftPhotos,
                artStyle: selectedArtStyle,
                location: storyLocation,
                date: storyDate,
                savesDraft: savesDraft,
                isPrivate: isPrivateEntry,
                fontChoiceRawValue: selectedFontChoice.rawValue,
                textColorIndex: selectedTextColorIndex,
                textSize: previewTextSize,
                paperStyleRawValue: selectedPaperStyleChoice.rawValue,
                paperColorIndex: selectedPaperColorIndex,
                thumbnail: draftThumbnail
            )
            isDraftSaved = !CreateEntryDraftStore.loadAll().isEmpty
        }

        clearEditor()
        activeDraftID = nil
        withAnimation(.snappy(duration: 0.32)) {
            dismissCreate()
        }
    }

    private func discardDraftAndExit() {
        clearEditor()
        if let activeDraftID {
            CreateEntryDraftStore.delete(id: activeDraftID)
        }
        activeDraftID = nil
        isDraftSaved = !CreateEntryDraftStore.loadAll().isEmpty
        withAnimation(.snappy(duration: 0.32)) {
            dismissCreate()
        }
    }

    private func clearEditor() {
        storyTitle = ""
        entryText = ""
        storyboardPhotos = Array(repeating: nil, count: 5)
        selectedArtStyle = "Anime"
        storyLocation = ""
        storyDate = Date()
        savesDraft = true
        isPrivateEntry = false
        selectedFontChoice = .sans
        selectedTextColorIndex = 0
        previewTextSize = 0.36
        textFormattingRequest = nil
        selectedPaperStyleChoice = .collegeRuled
        selectedPaperColorIndex = 0
        isShowingEntryOptionsPage = false
        loadedDraftSnapshot = nil
    }

    private func loadSavedDraftIfNeeded() {
        guard let activeDraftID else {
            return
        }

        guard let draft = CreateEntryDraftStore.load(id: activeDraftID) else {
            self.activeDraftID = nil
            isDraftSaved = !CreateEntryDraftStore.loadAll().isEmpty
            clearEditor()
            return
        }

        storyTitle = draft.title
        entryText = draft.text
        let photos = Array(draft.photos.prefix(5))
        storyboardPhotos = photos.map(Optional.some)
            + Array(repeating: nil, count: max(0, 5 - photos.count))
        selectedArtStyle = draft.artStyle
        storyLocation = draft.location
        storyDate = draft.date
        savesDraft = draft.savesDraft
        isPrivateEntry = draft.isPrivate
        selectedFontChoice = CreateFontChoice.savedValue(draft.fontChoiceRawValue)
        selectedTextColorIndex = min(max(draft.textColorIndex ?? 0, 0), CreateFormattingPalette.textColors.count - 1)
        previewTextSize = min(max(draft.textSize ?? 0.36, 0), 1)
        selectedPaperStyleChoice = draft.paperStyleRawValue.flatMap(CreatePaperStyleChoice.init(rawValue:)) ?? .collegeRuled
        selectedPaperColorIndex = min(max(draft.paperColorIndex ?? 0, 0), CreateFormattingPalette.paperColors.count - 1)
        loadedDraftSnapshot = currentDraftSnapshot(id: draft.id)
    }

    private func currentDraftSnapshot(id: UUID) -> LoadedCreateEntryDraftSnapshot {
        LoadedCreateEntryDraftSnapshot(
            id: id,
            title: storyTitle,
            text: entryText,
            photos: storyboardPhotos.compactMap { $0 },
            artStyle: selectedArtStyle,
            location: storyLocation,
            date: storyDate,
            savesDraft: savesDraft,
            isPrivate: isPrivateEntry,
            fontChoiceRawValue: selectedFontChoice.rawValue,
            textColorIndex: selectedTextColorIndex,
            textSize: previewTextSize,
            paperStyleRawValue: selectedPaperStyleChoice.rawValue,
            paperColorIndex: selectedPaperColorIndex
        )
    }

    private var createEntryContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            entryDraftStepContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private var entryDraftStepContent: some View {
        GeometryReader { proxy in
            let scrollContentHeight = editorScrollContentHeight(for: proxy.size.height)

            ScrollView {
                ZStack(alignment: .topLeading) {
                    NotebookPaperBackground(
                        paperColor: selectedPaperSurfaceColor,
                        paperImageName: selectedPaperStyleChoice.backgroundImageName,
                        showsPaperWash: false,
                        showsRuledLines: selectedPaperStyleChoice.showsRuledLines,
                        showsNotebookChrome: selectedPaperStyleChoice.showsNotebookChrome,
                        firstRuledLineY: NotebookMetrics.firstNotebookRuleY
                    )
                    .frame(maxWidth: .infinity, minHeight: scrollContentHeight, maxHeight: .infinity)

                    NotebookEditorContent(
                        storyTitle: $storyTitle,
                        entryText: $entryText,
                        isTitleFocused: $isTitleFocused,
                        editorFocusRequestID: editorFocusRequestID,
                        editorBlurRequestID: editorBlurRequestID,
                        formattingRequest: textFormattingRequest,
                        bodyPlaceholder: "Start writing...",
                        scrollsInternally: false,
                        pageHeight: scrollContentHeight,
                        textStyle: selectedTextStyle,
                        showsTitleRule: selectedPaperStyleChoice.showsNotebookChrome,
                        leadingContentPadding: selectedPaperStyleChoice.leadingContentPadding,
                        leadingTextPadding: selectedPaperStyleChoice.leadingTextPadding,
                        usesTexturedPaperEffect: selectedPaperStyleChoice.usesTexturedPaperTextEffect,
                        onTitleSubmit: {
                            editorFocusRequestID += 1
                        }
                    )
                }
                .frame(maxWidth: .infinity, minHeight: scrollContentHeight)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Group {
                    if isKeyboardVisible {
                        entryDraftKeyboardBar
                    } else {
                        entryDraftBottomBar
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.snappy(duration: 0.22), value: isKeyboardVisible)
            .animation(.snappy(duration: 0.22), value: hasStoryboardPhotos)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func editorScrollContentHeight(for visibleHeight: CGFloat) -> CGFloat {
        max(visibleHeight, UIScreen.main.bounds.height) * 2
    }

    private var editorFloatingToolBottomPadding: CGFloat {
        if isFullScreenEditorVisible {
            return 24
        }

        if isKeyboardVisible {
            return 68
        }

        return hasStoryboardPhotos ? 232 : 196
    }

    private var entryDraftBottomBar: some View {
        VStack(spacing: 14) {
            photoStripSection
            nextEntryOptionsButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private var entryDraftKeyboardBar: some View {
        HStack(spacing: 8) {
            keyboardPhotoButton

            Spacer(minLength: 0)

            HStack(spacing: 1) {
                keyboardFormattingButton(
                    title: "B",
                    accessibilityLabel: "Bold",
                    isSelected: false
                ) {
                    sendTextFormattingCommand(.bold)
                }

                keyboardFormattingButton(
                    title: "I",
                    accessibilityLabel: "Italic",
                    isSelected: false,
                    isItalic: true
                ) {
                    sendTextFormattingCommand(.italic)
                }

                keyboardFormattingButton(
                    title: "U",
                    accessibilityLabel: "Underline",
                    isSelected: false,
                    isUnderlined: true
                ) {
                    sendTextFormattingCommand(.underline)
                }

                keyboardFormattingButton(
                    title: "S",
                    accessibilityLabel: "Strikethrough",
                    isSelected: false,
                    isStrikethrough: true
                ) {
                    sendTextFormattingCommand(.strikethrough)
                }
            }

            Spacer(minLength: 0)

            keyboardToolButton(
                systemName: "keyboard.chevron.compact.down",
                accessibilityLabel: "Close keyboard",
                isSelected: false,
                action: dismissKeyboard
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color.homePageBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.storyBorder.opacity(0.45))
                .frame(height: 0.5)
        }
    }

    private func sendTextFormattingCommand(_ command: NotebookTextFormattingCommand) {
        isTitleFocused = false
        textFormattingRequestID += 1
        textFormattingRequest = NotebookTextFormattingRequest(
            id: textFormattingRequestID,
            command: command
        )
    }

    private func keyboardToolButton(
        systemName: String,
        accessibilityLabel: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.72))
                .frame(width: 34, height: 44)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.storyPurple.opacity(0.12))
                        }
                    }
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func keyboardFormattingButton(
        title: String,
        accessibilityLabel: String,
        isSelected: Bool,
        isItalic: Bool = false,
        isUnderlined: Bool = false,
        isStrikethrough: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(isItalic ? .system(size: 17, weight: .bold, design: .serif).italic() : .system(size: 17, weight: .bold, design: .serif))
                .underline(isUnderlined)
                .strikethrough(isStrikethrough)
                .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.72))
                .frame(width: 34, height: 44)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.storyPurple.opacity(0.12))
                        }
                    }
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var keyboardPhotoButton: some View {
        Button {
            dismissKeyboard()
            selectedPhotoSlot = nextAvailablePhotoSlot
            isShowingPhotoSourceDialog = true
        } label: {
            KeyboardPhotoAddButton(hasPhotos: hasStoryboardPhotos)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add reference photos")
        .disabled(nextAvailablePhotoSlot == nil)
        .opacity(nextAvailablePhotoSlot == nil ? 0.42 : 1)
    }

    private var editorFloatingToolStack: some View {
        VStack(spacing: 10) {
            expandEditorButton

            if !isFullScreenEditorVisible {
                fontEditorButton
                paperStyleButton
            }
        }
    }

    private var expandEditorButton: some View {
        Button {
            dismissKeyboard()
            withAnimation(.snappy(duration: 0.22)) {
                isFullScreenEditorVisible.toggle()
            }
        } label: {
            editorFloatingToolIcon {
                Image(systemName: isFullScreenEditorVisible ? "arrow.down.right.and.arrow.up.left" : "viewfinder")
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFullScreenEditorVisible ? "Show Create controls" : "Show full screen editor")
    }

    private var fontEditorButton: some View {
        Button {
            dismissKeyboard()
            selectedFormattingTab = .fontStyle
            isShowingFormattingSheet = true
        } label: {
            editorFloatingToolIcon {
                Text("Aa")
                    .font(.system(size: 18, weight: .bold, design: .serif))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Font options")
    }

    private var paperStyleButton: some View {
        Button {
            dismissKeyboard()
            selectedFormattingTab = .paperStyle
            isShowingFormattingSheet = true
        } label: {
            editorFloatingToolIcon {
                Image(systemName: "doc")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Paper style options")
    }

    private func editorFloatingToolIcon<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .foregroundStyle(Color.storyInk.opacity(0.76))
            .frame(width: 48, height: 48)
            .background(Color.white.opacity(0.82), in: Circle())
            .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
            .contentShape(Circle())
    }

    private var entryOptionsStepContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            journalDestinationCard
            // artStylePickerSection
            storyDetailsCard
            entryPrivacyCard
            generateStoryboardButton
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var nextEntryOptionsButton: some View {
        Button {
            showEntryOptionsPage()
        } label: {
            HStack(spacing: 8) {
                Text("Next")

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.storyPurple, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .shadow(color: Color.storyPurple.opacity(0.18), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Next")
    }

    private var selectedEntryJournalTitle: String? {
        switch entryDestination {
        case .daily:
            return DailyJournalData.allChapters().first?.title
        case .custom:
            return selectedCustomJournalTitle
        }
    }

    private var hasStoryboardPhotos: Bool {
        storyboardPhotos.contains { $0 != nil }
    }

    private func addCurrentEntry(to journalTitle: String) {
        let trimmedTitle = storyTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty || !trimmedBody.isEmpty else {
            return
        }

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let trimmedLocation = storyLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = PrototypeEntry(
            weekday: weekdayFormatter.string(from: storyDate).uppercased(),
            day: dayFormatter.string(from: storyDate),
            title: trimmedTitle.isEmpty ? "Untitled Entry" : trimmedTitle,
            body: trimmedBody,
            time: timeFormatter.string(from: storyDate),
            location: trimmedLocation.isEmpty ? nil : trimmedLocation,
            imageNames: []
        )

        StoryEntryStore.add(entry, to: journalTitle)
    }

    private var journalDestinationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.storyPurple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Journal")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)

                    Text("Choose where to add this entry")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                journalDestinationButton(
                    title: "Daily Journal",
                    subtitle: "Add to today's daily journal",
                    icon: "calendar",
                    isSelected: entryDestination == .daily
                ) {
                    entryDestination = .daily
                    dismissKeyboard()
                }

                journalDestinationButton(
                    title: "Custom Journal",
                    subtitle: selectedCustomJournalTitle.map { "Adding to \($0)" } ?? "Add to an existing or new journal",
                    icon: "book",
                    isSelected: entryDestination == .custom
                ) {
                    entryDestination = .custom
                    isShowingJournalDestinationSheet = true
                    dismissKeyboard()
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.68), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 9, y: 3)
    }

    private func journalDestinationButton(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(Color.storyPurple)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.storyInk)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.storyPurple : Color.storyBorder)
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .background(Color.white.opacity(isSelected ? 0.96 : 0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.storyPurple.opacity(0.34) : Color.storyBorder.opacity(0.62), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var photoStripSection: some View {
        Group {
            if hasStoryboardPhotos {
                populatedPhotoStripSection
            } else {
                emptyPhotoStripSection
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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

    private var photoStripHeader: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "paperclip")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color.storyInk.opacity(0.86))
                .rotationEffect(.degrees(-18))
                .frame(width: 20, height: 20)

            Text("Photos")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(Color.storyInk)
        }
    }

    private var emptyPhotoStripSection: some View {
        HStack(alignment: .center, spacing: 10) {
            photoStripHeader

            Spacer(minLength: 10)

            photoLimitText

            addPhotoStripButton
        }
    }

    private var populatedPhotoStripSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                photoStripHeader

                Spacer(minLength: 10)

                photoLimitText
            }

            ScrollView(.horizontal, showsIndicators: false) {
                photoStripContent
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
            }
            .frame(height: 76)
        }
    }

    private var photoLimitText: some View {
        Text("Up to 5 photos")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.homeMutedText.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }

    private var photoStripContent: some View {
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
                addPhotoStripButton
            }
        }
    }

    private var addPhotoStripButton: some View {
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

    private var storyDetailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Story Details")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)

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
                title: "Save Entry",
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

private struct AddToJournalSheet: View {
    @Binding var selectedJournalTitle: String?

    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: AddToJournalTab = .existing
    @State private var searchText = ""
    @State private var newJournalName = ""
    @State private var selectedSymbol = "book.closed.fill"

    private let coverSymbols = [
        "book.closed.fill",
        "sun.max.fill",
        "moon.stars.fill",
        "heart.fill",
        "leaf.fill",
        "building.2.fill"
    ]

    private var journals: [PrototypeChapter] {
        DailyJournalData.allChapters()
    }

    private var filteredJournals: [PrototypeChapter] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return journals
        }

        return journals.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    private var trimmedNewJournalName: String {
        newJournalName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tabBar

            Group {
                switch selectedTab {
                case .existing:
                    existingJournalList
                case .new:
                    newJournalForm
                }
            }
        }
        .padding(.top, 18)
        .background(Color.homePageBackground)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.storyPurple)

            Spacer()

            Text("Add to Journal")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Color.clear
                .frame(width: 52, height: 20)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AddToJournalTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 9) {
                        Text(tab.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(selectedTab == tab ? Color.storyPurple : Color.storyInk.opacity(0.72))

                        Capsule()
                            .fill(selectedTab == tab ? Color.storyPurple : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var existingJournalList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)

                TextField("Search journals...", text: $searchText)
                    .font(.system(size: 13, weight: .medium))
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(filteredJournals) { journal in
                        Button {
                            onSelect(journal.title)
                        } label: {
                            existingJournalRow(journal)
                        }
                        .buttonStyle(.plain)

                        if journal.id != filteredJournals.last?.id {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
            }

            Button {
                if let selectedJournalTitle {
                    onSelect(selectedJournalTitle)
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.storyPurple.opacity(0.94), Color.storyPurple],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedJournalTitle == nil)
            .opacity(selectedJournalTitle == nil ? 0.48 : 1)
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
    }

    private func existingJournalRow(_ journal: PrototypeChapter) -> some View {
        HStack(spacing: 12) {
            AddToJournalCoverIcon(
                symbol: journal.symbol,
                color: journal.color,
                isSelected: selectedJournalTitle == journal.title
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(journal.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.storyInk)

                Text("\(journal.entries.count) \(journal.entries.count == 1 ? "entry" : "entries")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.homeMutedText)
            }

            Spacer()

            Image(systemName: selectedJournalTitle == journal.title ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(selectedJournalTitle == journal.title ? Color.storyPurple : Color.storyBorder)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var newJournalForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(spacing: 9) {
                Image(systemName: "book.closed.badge.plus")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Color.storyPurple)
                    .frame(width: 72, height: 72)
                    .background(Color.storyPurple.opacity(0.11), in: Circle())

                Text("Create New Journal")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Text("Give your journal a name and cover to get started.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.homeMutedText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 18)

            VStack(alignment: .leading, spacing: 8) {
                Text("Journal Name")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.storyInk)

                TextField("e.g., My Thoughts, Adventures...", text: $newJournalName)
                    .font(.system(size: 14, weight: .medium))
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.storyPurple.opacity(0.52), lineWidth: 1.2)
                    )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Cover")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.storyInk)

                HStack(spacing: 10) {
                    ForEach(coverSymbols, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                        } label: {
                            AddToJournalCoverIcon(
                                symbol: symbol,
                                color: Color.storyPurple,
                                isSelected: selectedSymbol == symbol
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 0)

            Button {
                createJournal()
            } label: {
                Text("Create Journal")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.storyPurple.opacity(0.94), Color.storyPurple],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(trimmedNewJournalName.isEmpty)
            .opacity(trimmedNewJournalName.isEmpty ? 0.48 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private func createJournal() {
        guard !trimmedNewJournalName.isEmpty else {
            return
        }

        let journal = PrototypeChapter(
            title: trimmedNewJournalName,
            subtitle: "Personal journal",
            color: Color.storyPurple,
            symbol: selectedSymbol,
            coverImageName: nil,
            kind: .journal,
            isFavorite: false,
            entries: []
        )

        UserChapterStore.add(journal)
        onSelect(journal.title)
    }
}

private struct AddToJournalCoverIcon: View {
    let symbol: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(isSelected ? 0.94 : 0.28),
                            color.opacity(isSelected ? 0.76 : 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isSelected ? color.opacity(0.65) : color.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

            Rectangle()
                .fill(Color.white.opacity(isSelected ? 0.34 : 0.56))
                .frame(width: 4, height: 48)
                .padding(.leading, 5)

            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isSelected ? .white : color)
                .frame(width: 42, height: 54)
        }
        .frame(width: 48, height: 58)
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white, color)
                    .background(Color.white, in: Circle())
                    .offset(x: -1, y: -1)
            }
        }
    }
}

private enum AddToJournalTab: CaseIterable, Identifiable {
    case existing
    case new

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .existing:
            return "Existing"
        case .new:
            return "New Journal"
        }
    }
}

private enum KeyboardCornerRadiusRemover {
    static func removeKeyboardCornerRadius() {
        DispatchQueue.main.async {
            removeKeyboardCornerRadius(in: UIApplication.shared.connectedScenes)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            removeKeyboardCornerRadius(in: UIApplication.shared.connectedScenes)
        }
    }

    private static func removeKeyboardCornerRadius(in scenes: Set<UIScene>) {
        scenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { window in
                removeKeyboardCornerRadius(from: window)
            }
    }

    private static func removeKeyboardCornerRadius(from view: UIView) {
        let className = NSStringFromClass(type(of: view))

        if className.contains("UIInputSet") || className.contains("UIKeyboard") {
            view.layer.cornerRadius = 0
            view.layer.maskedCorners = []
        }

        view.subviews.forEach(removeKeyboardCornerRadius(from:))
    }
}

struct ExpandedEntryEditor: View {
    @Binding var entryText: String
    @Binding var storyTitle: String
    var textStyle: NotebookTextStyle = .default
    var paperColor: Color = .homePageBackground
    private var paperImageName: String?
    private var showsRuledLines = true
    private var showsNotebookChrome = true
    private var leadingContentPadding = NotebookMetrics.marginLeading
    private var leadingTextPadding = NotebookMetrics.textLeadingInset

    @FocusState private var isTitleFocused: Bool
    @State private var editorFocusRequestID = 0

    init(
        entryText: Binding<String>,
        storyTitle: Binding<String>,
        textStyle: NotebookTextStyle = .default,
        paperColor: Color = .homePageBackground
    ) {
        self._entryText = entryText
        self._storyTitle = storyTitle
        self.textStyle = textStyle
        self.paperColor = paperColor
    }

    fileprivate init(
        entryText: Binding<String>,
        storyTitle: Binding<String>,
        textStyle: NotebookTextStyle = .default,
        paperColor: Color = .homePageBackground,
        paperStyle: CreatePaperStyleChoice
    ) {
        self._entryText = entryText
        self._storyTitle = storyTitle
        self.textStyle = textStyle
        self.paperColor = paperColor
        self.paperImageName = paperStyle.backgroundImageName
        self.showsRuledLines = paperStyle.showsRuledLines
        self.showsNotebookChrome = paperStyle.showsNotebookChrome
        self.leadingContentPadding = paperStyle.leadingContentPadding
        self.leadingTextPadding = paperStyle.leadingTextPadding
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    NotebookPaperBackground(
                        paperColor: paperColor,
                        paperImageName: paperImageName,
                        showsPaperWash: false,
                        showsRuledLines: showsRuledLines,
                        showsNotebookChrome: showsNotebookChrome,
                        firstRuledLineY: NotebookMetrics.firstNotebookRuleY
                    )
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, maxHeight: .infinity)

                    NotebookEditorContent(
                        storyTitle: $storyTitle,
                        entryText: $entryText,
                        isTitleFocused: $isTitleFocused,
                        editorFocusRequestID: editorFocusRequestID,
                        bodyPlaceholder: "Start writing...",
                        scrollsInternally: false,
                        pageHeight: proxy.size.height,
                        textStyle: textStyle,
                        showsTitleRule: showsNotebookChrome,
                        leadingContentPadding: leadingContentPadding,
                        leadingTextPadding: leadingTextPadding,
                        usesTexturedPaperEffect: paperImageName != nil,
                        onBodyTap: {
                            isTitleFocused = false
                            editorFocusRequestID += 1
                        },
                        onTitleSubmit: {
                            editorFocusRequestID += 1
                        }
                    )
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(paperColor)
            .notebookPageChrome()
        }
        .background(paperColor)
        .navigationTitle("Write")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(paperColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                .font(.system(size: 14, weight: .bold))
            }
        }
    }
}

struct NotebookPaperBackground: View {
    var paperColor = Color.homePageBackground
    var paperImageName: String?
    var showsPaperWash = true
    var showsRuledLines = true
    var showsNotebookChrome = true
    var firstRuledLineY: CGFloat = 135

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if let paperImageName {
                    Image(paperImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    paperColor
                }

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

                if showsRuledLines {
                    ruledLines(in: proxy.size)
                }

                if showsNotebookChrome {
                    Rectangle()
                        .fill(Color.storyRose.opacity(0.52))
                        .frame(width: 1.2)
                        .padding(.leading, NotebookMetrics.marginLeading)

                    pageHoles
                        .padding(.leading, 20)
                        .padding(.top, 92)
                }
            }
        }
    }

    private func ruledLines(in size: CGSize) -> some View {
        Path { path in
            var y = firstRuledLineY
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += NotebookMetrics.ruleSpacing
            }
        }
        .stroke(NotebookMetrics.ruleColor, lineWidth: 1)
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

private struct CreateFormattingSheet: View {
    @Binding var selectedTab: CreateFormattingTab
    @Binding var selectedFont: CreateFontChoice
    @Binding var selectedPaperStyle: CreatePaperStyleChoice
    @Binding var selectedTextColorIndex: Int
    @Binding var selectedPaperColorIndex: Int
    @Binding var previewTextSize: Double

    @Environment(\.dismiss) private var dismiss

    private var selectedTextColor: Color {
        CreateFormattingPalette.textColors[
            min(max(selectedTextColorIndex, 0), CreateFormattingPalette.textColors.count - 1)
        ].color
    }

    private var selectedPaperColor: Color {
        CreateFormattingPalette.paperColors[
            min(max(selectedPaperColorIndex, 0), CreateFormattingPalette.paperColors.count - 1)
        ]
    }

    private var selectedPreviewFontSize: CGFloat {
        CGFloat(14 + previewTextSize * 8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.storyInk.opacity(0.58))
                        .frame(width: 44, height: 44)
                        .background(Color.homeInputGray.opacity(0.85), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close formatting options")
            }
            .overlay {
                Text(selectedTab.title)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)
            }

            CreateFormattingTabSwitcher(selectedTab: $selectedTab)

            ScrollView(showsIndicators: false) {
                Group {
                    switch selectedTab {
                    case .fontStyle:
                        fontStyleContent
                    case .paperStyle:
                        paperStyleContent
                    }
                }
                .padding(.bottom, 18)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .background(Color.homePageBackground)
    }

    private var fontStyleContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            sheetSectionTitle("Font")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CreateFontChoice.allCases) { font in
                        Button {
                            selectedFont = font
                        } label: {
                            CreateFontOptionCard(font: font, isSelected: selectedFont == font)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 8)
                .padding(.bottom, 9)
                .padding(.top, 1)
            }

            Divider()
                .overlay(Color.storyBorder.opacity(0.42))

            sheetSectionTitle("Text Size")

            HStack(spacing: 14) {
                Text("A")
                    .font(selectedFont.swiftUIFont(size: 18, weight: .bold))
                    .foregroundStyle(Color.storyInk.opacity(0.82))

                Slider(value: $previewTextSize, in: 0...1)
                    .tint(Color.storyPurple)

                Text("A")
                    .font(selectedFont.swiftUIFont(size: 34, weight: .bold))
                    .foregroundStyle(Color.storyInk.opacity(0.82))
            }

            sheetSectionTitle("Text Color")
            CreateColorSwatchRow(
                colors: CreateFormattingPalette.textColors.map(\.color),
                selectedIndex: $selectedTextColorIndex,
                selectedCheckColor: .white,
                emphasizedBorderIndex: nil,
                showsMoreButton: false
            )

            Divider()
                .overlay(Color.storyBorder.opacity(0.42))

            sheetSectionTitle("Preview")
            formattingPreview
        }
    }

    private var paperStyleContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            sheetSectionTitle("Paper Style")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CreatePaperStyleChoice.allCases) { paperStyle in
                        Button {
                            selectedPaperStyle = paperStyle
                        } label: {
                            CreatePaperStyleOption(
                                style: paperStyle,
                                paperColor: CreateFormattingPalette.paperColors[selectedPaperColorIndex],
                                isSelected: selectedPaperStyle == paperStyle
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }

            if selectedPaperStyle.showsPaperColorOptions {
                sheetSectionTitle("Paper Color")
                CreateColorSwatchRow(
                    colors: CreateFormattingPalette.paperColors,
                    selectedIndex: $selectedPaperColorIndex,
                    selectedCheckColor: Color.storyPurple,
                    emphasizedBorderIndex: 1,
                    showsMoreButton: false
                )
            }

            Divider()
                .overlay(Color.storyBorder.opacity(0.42))

            sheetSectionTitle("Preview")
            formattingPreview
        }
    }

    private var formattingPreview: some View {
        Text("The little story found its voice on the page, one careful sentence at a time.")
            .font(selectedFont.swiftUIBodyFont(size: selectedPreviewFontSize))
            .foregroundStyle(selectedTextColor)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .padding(16)
            .background {
                CreatePaperPreview(style: selectedPaperStyle, paperColor: selectedPaperColor, ruledLineCount: 5)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.storyBorder.opacity(0.56), lineWidth: 1)
            )
    }

    private func sheetSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color.storyInk.opacity(0.92))
    }
}

private struct CreateFormattingTabSwitcher: View {
    @Binding var selectedTab: CreateFormattingTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CreateFormattingTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 15, weight: .semibold))

                        Text(tab.title)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.storyPurple : Color.storyInk.opacity(0.68))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(selectedTab == tab ? Color.white : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(selectedTab == tab ? Color.storyPurple : Color.clear, lineWidth: 1.4)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.45), lineWidth: 1)
        )
    }
}

private struct CreateFontOptionCard: View {
    let font: CreateFontChoice
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("Aa")
                .font(font.swiftUIBodyFont(size: 27))
                .foregroundStyle(Color.storyInk.opacity(0.9))

            Text(font.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.homeMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(width: 116, height: 96)
        .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.storyPurple : Color.storyBorder.opacity(0.45), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.storyPurple, in: Circle())
                    .offset(x: 8, y: 8)
            }
        }
    }
}

private struct CreatePaperStyleOption: View {
    let style: CreatePaperStyleChoice
    let paperColor: Color
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            CreatePaperPreview(style: style, paperColor: paperColor)
                .frame(width: 82, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.storyPurple : Color.storyBorder.opacity(0.45), lineWidth: isSelected ? 2 : 1)
                )
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.storyPurple, in: Circle())
                            .offset(x: 5, y: 5)
                    }
                }

            Text(style.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.homeMutedText)
                .frame(width: 92)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
    }
}

private struct CreatePaperPreview: View {
    let style: CreatePaperStyleChoice
    let paperColor: Color
    var ruledLineCount = 7

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                paperColor

                switch style {
                case .collegeRuled:
                    ruledLines(count: ruledLineCount, in: proxy.size)
                    marginLine(in: proxy.size)
                case .blank:
                    EmptyView()
                case .watercolorPaper, .cottonPaper, .recycledPaper:
                    if let backgroundImageName = style.backgroundImageName {
                        Image(backgroundImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    }
                }
            }
        }
    }

    private func ruledLines(count: Int, in size: CGSize) -> some View {
        ForEach(1...count, id: \.self) { index in
            Rectangle()
                .fill(Color.blue.opacity(0.16))
                .frame(height: 1)
                .offset(y: CGFloat(index) * size.height / CGFloat(count + 1))
        }
    }

    private func marginLine(in size: CGSize) -> some View {
        Rectangle()
            .fill(Color.storyRose.opacity(0.6))
            .frame(width: 1)
            .offset(x: size.width * 0.18)
    }

}

private struct CreateColorSwatchRow: View {
    let colors: [Color]
    @Binding var selectedIndex: Int
    let selectedCheckColor: Color
    let emphasizedBorderIndex: Int?
    let showsMoreButton: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(colors.indices, id: \.self) { index in
                    Button {
                        selectedIndex = index
                    } label: {
                        Circle()
                            .fill(colors[index])
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(
                                        emphasizedBorderIndex == index ? Color.storyInk.opacity(0.26) : Color.storyBorder.opacity(0.34),
                                        lineWidth: emphasizedBorderIndex == index ? 1.3 : 1
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.86), lineWidth: selectedIndex == index ? 6 : 0)
                            )
                            .overlay {
                                if selectedIndex == index {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(selectedCheckColor)
                                }
                            }
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                if showsMoreButton {
                    Button {
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.storyInk.opacity(0.58))
                            .frame(width: 50, height: 40)
                            .background(Color.homeInputGray.opacity(0.86), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("More colors")
                }
            }
            .padding(.vertical, 2)
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

    private let size: CGFloat = 56
    private let bottomPadding: CGFloat = 12

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
                    .frame(width: 16, height: 16)
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
        .frame(width: 52, height: 52)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.storyPurple.opacity(0.34), style: StrokeStyle(lineWidth: 1.1, dash: [4, 3]))
        )
        .accessibilityLabel("Add photos")
    }
}

struct KeyboardPhotoThumbnail: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 34, height: 34)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.storyInk.opacity(0.34), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            .frame(width: 38, height: 44)
            .contentShape(Rectangle())
    }
}

struct KeyboardPhotoAddButton: View {
    let hasPhotos: Bool

    var body: some View {
        Image(systemName: "photo.on.rectangle.angled")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color.storyInk.opacity(0.72))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}

struct KeyboardPhotoOverflowBadge: View {
    let count: Int

    var body: some View {
        Text("+\(count)")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.storyPurple)
            .frame(width: 34, height: 34)
            .background(Color.storyPurple.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.storyPurple.opacity(0.26), lineWidth: 1)
            )
            .frame(width: 38, height: 44)
            .accessibilityLabel("\(count) more reference photos")
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

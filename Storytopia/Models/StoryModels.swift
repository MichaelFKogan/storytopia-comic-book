import Foundation
import UIKit

enum StoryPage {
    case home
    case today
    case explore
    case create
    case entries
    case journal
    case profile
    case settings
}

enum EntryDatePrecision: String, CaseIterable, Identifiable, Codable {
    case noDate
    case exact
    case dateOnly
    case monthAndYear
    case yearOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noDate:
            "No Date"
        case .exact:
            "Date & Time"
        case .dateOnly:
            "Date Only"
        case .monthAndYear:
            "Month & Year"
        case .yearOnly:
            "Year Only"
        }
    }
}

enum StoryboardLayoutOption: String, CaseIterable, Identifiable {
    case twoRectangles
    case threeHorizontalPanels
    case threePanels
    case threeVerticalPanels
    case fourSquares
    case fourVerticalPanels
    case fourHorizontalRectangles
    case fiveHorizontalPanels
    case fiveClassic
    case sixSquares

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .twoRectangles:
            return "2 Rectangles"
        case .threeHorizontalPanels:
            return "3 Horiz."
        case .threePanels:
            return "3 Panels"
        case .threeVerticalPanels:
            return "3 Vertical"
        case .fourSquares:
            return "4 Squares"
        case .fourVerticalPanels:
            return "4 Vertical"
        case .fourHorizontalRectangles:
            return "4 Horiz."
        case .fiveHorizontalPanels:
            return "5 Horiz."
        case .fiveClassic:
            return "5 Panels"
        case .sixSquares:
            return "6 Squares"
        }
    }

    var panelCount: Int {
        switch self {
        case .twoRectangles:
            return 2
        case .threeHorizontalPanels, .threePanels, .threeVerticalPanels:
            return 3
        case .fourSquares, .fourVerticalPanels, .fourHorizontalRectangles:
            return 4
        case .fiveHorizontalPanels, .fiveClassic:
            return 5
        case .sixSquares:
            return 6
        }
    }

    var promptDescription: String {
        switch self {
        case .twoRectangles:
            return "two full-width horizontal rectangle panels stacked evenly from top to bottom."
        case .threeHorizontalPanels:
            return "three full-width horizontal rectangle panels stacked evenly from top to bottom."
        case .threePanels:
            return "one large full-width horizontal rectangle panel on top, with two equal rectangle panels side by side underneath."
        case .threeVerticalPanels:
            return "three equal tall vertical rectangle panels side by side in a single row."
        case .fourSquares:
            return "four equal square panels in a clean 2 by 2 grid."
        case .fourVerticalPanels:
            return "four equal tall vertical rectangle panels side by side in a single row."
        case .fourHorizontalRectangles:
            return "four full-width horizontal rectangle panels stacked evenly from top to bottom."
        case .fiveHorizontalPanels:
            return "five full-width horizontal rectangle panels stacked evenly from top to bottom."
        case .fiveClassic:
            return "row 1 has two equal 50-50 rectangle panels side by side; row 2 has one centered wide horizontal rectangle panel; row 3 has two equal 50-50 rectangle panels side by side."
        case .sixSquares:
            return "six equal square panels in a clean 2-column by 3-row grid."
        }
    }

    static func random(for imageCount: Int) -> StoryboardLayoutOption {
        let panelCount = storyboardPanelCount(for: imageCount)
        let matchingLayouts = allCases.filter { $0.panelCount == panelCount }
        return matchingLayouts.randomElement() ?? .fourSquares
    }
}

struct GeneratedStoryboard: Identifiable {
    let id: UUID
    let clientEntryID: UUID?
    let image: UIImage
    let promptText: String
    let artStyle: String
    let panelLayout: String?
    let sourcePhotoCount: Int
    let createdAt: Date
    let imageFileName: String?
    let storagePath: String?
    let cloudSyncState: String?
    let isPrimary: Bool

    init(
        id: UUID = UUID(),
        clientEntryID: UUID? = nil,
        image: UIImage,
        promptText: String,
        artStyle: String,
        panelLayout: String? = nil,
        sourcePhotoCount: Int,
        createdAt: Date = Date(),
        imageFileName: String? = nil,
        storagePath: String? = nil,
        cloudSyncState: String? = nil,
        isPrimary: Bool = true
    ) {
        self.id = id
        self.clientEntryID = clientEntryID
        self.image = image
        self.promptText = promptText
        self.artStyle = artStyle
        self.panelLayout = panelLayout
        self.sourcePhotoCount = sourcePhotoCount
        self.createdAt = createdAt
        self.imageFileName = imageFileName
        self.storagePath = storagePath
        self.cloudSyncState = cloudSyncState
        self.isPrimary = isPrimary
    }
}

struct CreateEntryReferencePhoto: Identifiable {
    static let fileExtension = "jpg"
    static let mimeType = "image/jpeg"

    let id: UUID
    let image: UIImage

    init(id: UUID = UUID(), image: UIImage) {
        self.id = id
        self.image = image
    }
}

enum OpenAITestConfig {
    // Prototype-only client key. Move image generation server-side before shipping.
    static var apiKey: String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
            !value.isEmpty,
            !value.hasPrefix("$(")
        else {
            return ""
        }

        return value
    }

    static let imageModel = "gpt-image-2"
}

struct CreateEntryDraft: Identifiable {
    let id: UUID
    let title: String
    let text: String
    let richText: NotebookRichTextDocument?
    let photos: [CreateEntryReferencePhoto]
    let artStyle: String
    let location: String
    let date: Date
    let datePrecision: EntryDatePrecision
    let savesDraft: Bool
    let isPrivate: Bool
    let status: String
    let fontChoiceRawValue: String?
    let textColorIndex: Int?
    let textSize: Double?
    let paperStyleRawValue: String?
    let paperColorIndex: Int?
    let isBold: Bool
    let isItalic: Bool
    let isUnderlined: Bool
    let isStrikethrough: Bool
    let isHighlighted: Bool
    let textAlignmentRawValue: String
    let thumbnail: UIImage?
    let createdAt: Date
    let updatedAt: Date
    let displayOrder: Int?
}

enum EntryLocationRecentStore {
    private static let storageKey = "StorytopiaRecentEntryLocations"
    private static let limit = 8

    static var all: [String] {
        UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }

    static func add(_ location: String) {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLocation.isEmpty else {
            return
        }

        let existingLocations = all.filter {
            $0.compare(trimmedLocation, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame
        }
        let updatedLocations = Array(([trimmedLocation] + existingLocations).prefix(limit))
        UserDefaults.standard.set(updatedLocations, forKey: storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

enum CreateEntryDraftStore {
    private static let metadataFileName = "draft.json"
    private static let thumbnailFileName = "thumbnail.jpg"

    static func loadAll() -> [CreateEntryDraft] {
        migrateLegacyDraftIfNeeded()

        guard
            let draftURLs = try? FileManager.default.contentsOfDirectory(
                at: draftsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        return draftURLs
            .compactMap(loadDraft(at:))
            .sorted(by: sortDrafts)
    }

    static func load(id: UUID) -> CreateEntryDraft? {
        migrateLegacyDraftIfNeeded()
        return loadDraft(at: directory(for: id))
    }

    @discardableResult
    static func save(
        id: UUID?,
        title: String,
        text: String,
        richText: NotebookRichTextDocument? = nil,
        photos: [UIImage],
        artStyle: String,
        location: String,
        date: Date,
        datePrecision: EntryDatePrecision = .exact,
        savesDraft: Bool,
        isPrivate: Bool,
        status: JournalEntryStatus = .draft,
        fontChoiceRawValue: String? = nil,
        textColorIndex: Int? = nil,
        textSize: Double? = nil,
        paperStyleRawValue: String? = nil,
        paperColorIndex: Int? = nil,
        isBold: Bool = false,
        isItalic: Bool = false,
        isUnderlined: Bool = false,
        isStrikethrough: Bool = false,
        isHighlighted: Bool = false,
        textAlignmentRawValue: String = "leading",
        thumbnail: UIImage? = nil
    ) -> UUID? {
        save(
            id: id,
            title: title,
            text: text,
            richText: richText,
            referencePhotos: photos.map { CreateEntryReferencePhoto(image: $0) },
            artStyle: artStyle,
            location: location,
            date: date,
            datePrecision: datePrecision,
            savesDraft: savesDraft,
            isPrivate: isPrivate,
            status: status,
            fontChoiceRawValue: fontChoiceRawValue,
            textColorIndex: textColorIndex,
            textSize: textSize,
            paperStyleRawValue: paperStyleRawValue,
            paperColorIndex: paperColorIndex,
            isBold: isBold,
            isItalic: isItalic,
            isUnderlined: isUnderlined,
            isStrikethrough: isStrikethrough,
            isHighlighted: isHighlighted,
            textAlignmentRawValue: textAlignmentRawValue,
            thumbnail: thumbnail
        )
    }

    @discardableResult
    static func save(
        id: UUID?,
        title: String,
        text: String,
        richText: NotebookRichTextDocument? = nil,
        referencePhotos: [CreateEntryReferencePhoto],
        artStyle: String,
        location: String,
        date: Date,
        datePrecision: EntryDatePrecision = .exact,
        savesDraft: Bool,
        isPrivate: Bool,
        status: JournalEntryStatus = .draft,
        fontChoiceRawValue: String? = nil,
        textColorIndex: Int? = nil,
        textSize: Double? = nil,
        paperStyleRawValue: String? = nil,
        paperColorIndex: Int? = nil,
        isBold: Bool = false,
        isItalic: Bool = false,
        isUnderlined: Bool = false,
        isStrikethrough: Bool = false,
        isHighlighted: Bool = false,
        textAlignmentRawValue: String = "leading",
        thumbnail: UIImage? = nil
    ) -> UUID? {
        let draftID = id ?? UUID()
        let draftDirectory = directory(for: draftID)
        let existingDraft = id.flatMap(load(id:))

        try? FileManager.default.removeItem(at: draftDirectory)

        do {
            try FileManager.default.createDirectory(
                at: draftDirectory,
                withIntermediateDirectories: true
            )

            var photoMetadata: [CreateEntryDraftPhotoMetadata] = []
            for (index, photo) in referencePhotos.enumerated() {
                guard let data = photo.image.storytopiaPreparedJPEGData(compressionQuality: 0.88) else {
                    continue
                }

                let fileName = "photo-\(index)-\(photo.id.uuidString).jpg"
                try data.write(
                    to: draftDirectory.appendingPathComponent(fileName),
                    options: [.atomic]
                )
                photoMetadata.append(
                    CreateEntryDraftPhotoMetadata(
                        id: photo.id,
                        fileName: fileName,
                        mimeType: CreateEntryReferencePhoto.mimeType
                    )
                )
            }

            let thumbnailToSave = thumbnail ?? existingDraft?.thumbnail
            if let thumbnailData = thumbnailToSave?.storytopiaPreparedJPEGData(compressionQuality: 0.86) {
                try thumbnailData.write(
                    to: draftDirectory.appendingPathComponent(thumbnailFileName),
                    options: [.atomic]
                )
            }

            let now = Date()
            let metadata = CreateEntryDraftMetadata(
                id: draftID,
                title: title,
                text: text,
                richText: richText,
                photoFileNames: photoMetadata.map(\.fileName),
                referencePhotos: photoMetadata,
                artStyle: artStyle,
                location: location,
                date: date,
                datePrecision: datePrecision,
                savesDraft: savesDraft,
                isPrivate: isPrivate,
                status: status.rawValue,
                fontChoiceRawValue: fontChoiceRawValue,
                textColorIndex: textColorIndex,
                textSize: textSize,
                paperStyleRawValue: paperStyleRawValue,
                paperColorIndex: paperColorIndex,
                isBold: isBold,
                isItalic: isItalic,
                isUnderlined: isUnderlined,
                isStrikethrough: isStrikethrough,
                isHighlighted: isHighlighted,
                textAlignmentRawValue: textAlignmentRawValue,
                createdAt: existingDraft?.createdAt ?? now,
                updatedAt: now,
                displayOrder: existingDraft?.displayOrder ?? defaultDisplayOrder(for: now)
            )
            let metadataData = try JSONEncoder().encode(metadata)
            try metadataData.write(
                to: draftDirectory.appendingPathComponent(metadataFileName),
                options: [.atomic]
            )
            return draftID
        } catch {
            try? FileManager.default.removeItem(at: draftDirectory)
            return nil
        }
    }

    static func delete(id: UUID) {
        try? FileManager.default.removeItem(at: directory(for: id))
    }

    static func saveThumbnail(_ thumbnail: UIImage, for id: UUID) {
        guard let thumbnailData = thumbnail.storytopiaPreparedJPEGData(compressionQuality: 0.86) else {
            return
        }

        try? thumbnailData.write(
            to: directory(for: id).appendingPathComponent(thumbnailFileName),
            options: [.atomic]
        )
    }

    static func saveOrder(_ orderedIDs: [UUID]) {
        for (displayOrder, id) in orderedIDs.enumerated() {
            let metadataURL = directory(for: id).appendingPathComponent(metadataFileName)
            guard
                let data = try? Data(contentsOf: metadataURL),
                var metadata = try? JSONDecoder().decode(CreateEntryDraftMetadata.self, from: data)
            else {
                continue
            }

            metadata.displayOrder = displayOrder

            guard let metadataData = try? JSONEncoder().encode(metadata) else {
                continue
            }

            try? metadataData.write(to: metadataURL, options: [.atomic])
        }
    }

    private static func loadDraft(at draftDirectory: URL) -> CreateEntryDraft? {
        let metadataURL = draftDirectory.appendingPathComponent(metadataFileName)
        guard
            let data = try? Data(contentsOf: metadataURL),
            var metadata = try? JSONDecoder().decode(CreateEntryDraftMetadata.self, from: data)
        else {
            return nil
        }

        let photoMetadata = metadata.normalizedPhotoMetadata()
        if metadata.referencePhotos == nil, !photoMetadata.isEmpty {
            metadata.referencePhotos = photoMetadata
            if let updatedData = try? JSONEncoder().encode(metadata) {
                try? updatedData.write(to: metadataURL, options: [.atomic])
            }
        }

        let photos = photoMetadata.compactMap { item -> CreateEntryReferencePhoto? in
            let fileName = item.fileName
            let photoURL = draftDirectory.appendingPathComponent(fileName)
            guard let data = try? Data(contentsOf: photoURL) else {
                return nil
            }
            return UIImage(data: data).map {
                CreateEntryReferencePhoto(id: item.id, image: $0)
            }
        }

        let thumbnailURL = draftDirectory.appendingPathComponent(thumbnailFileName)
        let thumbnail = (try? Data(contentsOf: thumbnailURL)).flatMap(UIImage.init(data:))

        return CreateEntryDraft(
            id: metadata.id ?? UUID(),
            title: metadata.title,
            text: metadata.text,
            richText: metadata.richText,
            photos: photos,
            artStyle: metadata.artStyle ?? "Anime",
            location: metadata.location ?? "",
            date: metadata.date ?? Date(),
            datePrecision: metadata.datePrecision ?? .exact,
            savesDraft: metadata.savesDraft ?? true,
            isPrivate: metadata.isPrivate ?? false,
            status: metadata.normalizedStatus,
            fontChoiceRawValue: metadata.fontChoiceRawValue,
            textColorIndex: metadata.textColorIndex,
            textSize: metadata.textSize,
            paperStyleRawValue: metadata.paperStyleRawValue,
            paperColorIndex: metadata.paperColorIndex,
            isBold: metadata.isBold ?? false,
            isItalic: metadata.isItalic ?? false,
            isUnderlined: metadata.isUnderlined ?? false,
            isStrikethrough: metadata.isStrikethrough ?? false,
            isHighlighted: metadata.isHighlighted ?? false,
            textAlignmentRawValue: metadata.textAlignmentRawValue ?? "leading",
            thumbnail: thumbnail,
            createdAt: metadata.createdAt ?? Date(),
            updatedAt: metadata.updatedAt ?? metadata.createdAt ?? Date(),
            displayOrder: metadata.displayOrder
        )
    }

    private static func sortDrafts(_ lhs: CreateEntryDraft, _ rhs: CreateEntryDraft) -> Bool {
        switch (lhs.displayOrder, rhs.displayOrder) {
        case let (lhsOrder?, rhsOrder?) where lhsOrder != rhsOrder:
            return lhsOrder < rhsOrder
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            return lhs.createdAt > rhs.createdAt
        }
    }

    private static func defaultDisplayOrder(for date: Date) -> Int {
        -Int(date.timeIntervalSinceReferenceDate * 1000)
    }

    private static func migrateLegacyDraftIfNeeded() {
        guard
            !FileManager.default.fileExists(atPath: draftsDirectory.path),
            let legacyDraft = loadDraft(at: legacyDraftDirectory)
        else {
            return
        }

        _ = save(
            id: nil,
            title: legacyDraft.title,
            text: legacyDraft.text,
            richText: legacyDraft.richText,
            referencePhotos: legacyDraft.photos,
            artStyle: legacyDraft.artStyle,
            location: legacyDraft.location,
            date: legacyDraft.date,
            savesDraft: legacyDraft.savesDraft,
            isPrivate: legacyDraft.isPrivate,
            fontChoiceRawValue: legacyDraft.fontChoiceRawValue,
            textColorIndex: legacyDraft.textColorIndex,
            textSize: legacyDraft.textSize,
            paperStyleRawValue: legacyDraft.paperStyleRawValue,
            paperColorIndex: legacyDraft.paperColorIndex,
            isBold: legacyDraft.isBold,
            isItalic: legacyDraft.isItalic,
            isUnderlined: legacyDraft.isUnderlined,
            isStrikethrough: legacyDraft.isStrikethrough,
            isHighlighted: legacyDraft.isHighlighted,
            textAlignmentRawValue: legacyDraft.textAlignmentRawValue
        )
        try? FileManager.default.removeItem(at: legacyDraftDirectory)
    }

    private static func directory(for id: UUID) -> URL {
        draftsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    private static var draftsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CreateEntryDrafts", isDirectory: true)
    }

    private static var legacyDraftDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CreateEntryDraft", isDirectory: true)
    }
}

private struct CreateEntryDraftMetadata: Codable {
    var id: UUID?
    var title: String
    var text: String
    var richText: NotebookRichTextDocument?
    var photoFileNames: [String]
    var referencePhotos: [CreateEntryDraftPhotoMetadata]?
    var artStyle: String?
    var location: String?
    var date: Date?
    var datePrecision: EntryDatePrecision?
    var savesDraft: Bool?
    var isPrivate: Bool?
    var status: String?
    var fontChoiceRawValue: String?
    var textColorIndex: Int?
    var textSize: Double?
    var paperStyleRawValue: String?
    var paperColorIndex: Int?
    var isBold: Bool?
    var isItalic: Bool?
    var isUnderlined: Bool?
    var isStrikethrough: Bool?
    var isHighlighted: Bool?
    var textAlignmentRawValue: String?
    var createdAt: Date?
    var updatedAt: Date?
    var displayOrder: Int?

    func normalizedPhotoMetadata() -> [CreateEntryDraftPhotoMetadata] {
        if let referencePhotos {
            return referencePhotos
        }

        return photoFileNames.map {
            CreateEntryDraftPhotoMetadata(
                id: UUID(),
                fileName: $0,
                mimeType: CreateEntryReferencePhoto.mimeType
            )
        }
    }

    var normalizedStatus: String {
        guard
            let status,
            JournalEntryStatus(rawValue: status) != nil
        else {
            return JournalEntryStatus.draft.rawValue
        }

        return status
    }
}

private struct CreateEntryDraftPhotoMetadata: Codable {
    var id: UUID
    var fileName: String
    var mimeType: String
}

enum GeneratedStoryboardStore {
    private static let metadataKey = "StorytopiaGeneratedStoryboardMetadata"

    static func load() -> [GeneratedStoryboard] {
        guard
            let metadataData = UserDefaults.standard.data(forKey: metadataKey),
            let metadata = try? JSONDecoder().decode([GeneratedStoryboardMetadata].self, from: metadataData)
        else {
            return []
        }

        return metadata.compactMap { item in
            let imageURL = imagesDirectory.appendingPathComponent(item.imageFileName)
            guard
                let imageData = try? Data(contentsOf: imageURL),
                let image = UIImage(data: imageData)
            else {
                return nil
            }

            return GeneratedStoryboard(
                id: item.id,
                clientEntryID: item.clientEntryID,
                image: image,
                promptText: item.promptText,
                artStyle: item.artStyle,
                panelLayout: item.panelLayout,
                sourcePhotoCount: item.sourcePhotoCount,
                createdAt: item.createdAt,
                imageFileName: item.imageFileName,
                storagePath: item.storagePath,
                cloudSyncState: item.cloudSyncState,
                isPrimary: item.isPrimary ?? true
            )
        }
    }

    static func save(_ storyboards: [GeneratedStoryboard]) {
        let metadata = storyboards.compactMap { storyboard -> GeneratedStoryboardMetadata? in
            guard let imageFileName = storyboard.imageFileName else {
                return nil
            }

            return GeneratedStoryboardMetadata(
                id: storyboard.id,
                clientEntryID: storyboard.clientEntryID,
                promptText: storyboard.promptText,
                artStyle: storyboard.artStyle,
                panelLayout: storyboard.panelLayout,
                sourcePhotoCount: storyboard.sourcePhotoCount,
                createdAt: storyboard.createdAt,
                imageFileName: imageFileName,
                storagePath: storyboard.storagePath,
                cloudSyncState: storyboard.cloudSyncState,
                isPrimary: storyboard.isPrimary
            )
        }

        guard let metadataData = try? JSONEncoder().encode(metadata) else {
            return
        }

        UserDefaults.standard.set(metadataData, forKey: metadataKey)
    }

    static func delete(_ storyboards: [GeneratedStoryboard]) {
        for storyboard in storyboards {
            guard let imageFileName = storyboard.imageFileName else {
                continue
            }

            let imageURL = imagesDirectory.appendingPathComponent(imageFileName)
            try? FileManager.default.removeItem(at: imageURL)
        }
    }

    static func persistedStoryboard(
        image: UIImage,
        clientEntryID: UUID,
        promptText: String,
        artStyle: String,
        panelLayout: String?,
        sourcePhotoCount: Int,
        id: UUID = UUID(),
        storagePath: String? = nil,
        cloudSyncState: String? = nil,
        isPrimary: Bool = true
    ) throws -> GeneratedStoryboard {
        try FileManager.default.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )

        let imageFileName = "\(id.uuidString).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(imageFileName)

        guard let imageData = image.storytopiaPreparedJPEGData(compressionQuality: 0.9) else {
            throw StoryboardGenerationError.invalidRequest
        }

        try imageData.write(to: imageURL, options: [.atomic])

        return GeneratedStoryboard(
            id: id,
            clientEntryID: clientEntryID,
            image: image,
            promptText: promptText,
            artStyle: artStyle,
            panelLayout: panelLayout,
            sourcePhotoCount: sourcePhotoCount,
            imageFileName: imageFileName,
            storagePath: storagePath,
            cloudSyncState: cloudSyncState,
            isPrimary: isPrimary
        )
    }

    static func merging(_ storyboard: GeneratedStoryboard, into storyboards: [GeneratedStoryboard]) -> [GeneratedStoryboard] {
        var merged = storyboards.map { existing in
            guard
                storyboard.isPrimary,
                existing.id != storyboard.id,
                existing.clientEntryID == storyboard.clientEntryID
            else {
                return existing
            }

            return GeneratedStoryboard(
                id: existing.id,
                clientEntryID: existing.clientEntryID,
                image: existing.image,
                promptText: existing.promptText,
                artStyle: existing.artStyle,
                panelLayout: existing.panelLayout,
                sourcePhotoCount: existing.sourcePhotoCount,
                createdAt: existing.createdAt,
                imageFileName: existing.imageFileName,
                storagePath: existing.storagePath,
                cloudSyncState: existing.cloudSyncState,
                isPrimary: false
            )
        }
        if let index = merged.firstIndex(where: { $0.id == storyboard.id }) {
            merged[index] = storyboard
        } else {
            merged.insert(storyboard, at: 0)
        }
        return merged
    }

    private static var imagesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GeneratedStoryboards", isDirectory: true)
    }
}

struct GeneratedStoryboardMetadata: Codable {
    let id: UUID
    let clientEntryID: UUID?
    let promptText: String
    let artStyle: String
    let panelLayout: String?
    let sourcePhotoCount: Int
    let createdAt: Date
    let imageFileName: String
    let storagePath: String?
    let cloudSyncState: String?
    let isPrimary: Bool?
}

enum StoryboardGenerationError: LocalizedError {
    case missingAPIKey
    case invalidRequest
    case invalidResponse
    case noGeneratedImage
    case openAIMessage(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an OpenAI API key before generating a storyboard."
        case .invalidRequest:
            return "The storyboard request could not be prepared."
        case .invalidResponse:
            return "OpenAI returned a response Storytopia could not read."
        case .noGeneratedImage:
            return "OpenAI did not return a storyboard image."
        case .openAIMessage(let message):
            return message
        }
    }
}

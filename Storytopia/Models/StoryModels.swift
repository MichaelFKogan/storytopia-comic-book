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
    let image: UIImage
    let promptText: String
    let artStyle: String
    let sourcePhotoCount: Int
    let createdAt: Date
    let imageFileName: String?

    init(
        id: UUID = UUID(),
        image: UIImage,
        promptText: String,
        artStyle: String,
        sourcePhotoCount: Int,
        createdAt: Date = Date(),
        imageFileName: String? = nil
    ) {
        self.id = id
        self.image = image
        self.promptText = promptText
        self.artStyle = artStyle
        self.sourcePhotoCount = sourcePhotoCount
        self.createdAt = createdAt
        self.imageFileName = imageFileName
    }
}

enum OpenAITestConfig {
    // Temporary test-only client key. Remove this before pushing or shipping.
    static let apiKey = ""
    static let imageModel = "gpt-image-2"
}

struct CreateEntryDraft: Identifiable {
    let id: UUID
    let title: String
    let text: String
    let richText: NotebookRichTextDocument?
    let photos: [UIImage]
    let artStyle: String
    let location: String
    let date: Date
    let savesDraft: Bool
    let isPrivate: Bool
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
        savesDraft: Bool,
        isPrivate: Bool,
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

            var photoFileNames: [String] = []
            for (index, photo) in photos.enumerated() {
                guard let data = photo.storytopiaPreparedJPEGData(compressionQuality: 0.88) else {
                    continue
                }

                let fileName = "photo-\(index).jpg"
                try data.write(
                    to: draftDirectory.appendingPathComponent(fileName),
                    options: [.atomic]
                )
                photoFileNames.append(fileName)
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
                photoFileNames: photoFileNames,
                artStyle: artStyle,
                location: location,
                date: date,
                savesDraft: savesDraft,
                isPrivate: isPrivate,
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
            let metadata = try? JSONDecoder().decode(CreateEntryDraftMetadata.self, from: data)
        else {
            return nil
        }

        let photos = metadata.photoFileNames.compactMap { fileName -> UIImage? in
            let photoURL = draftDirectory.appendingPathComponent(fileName)
            guard let data = try? Data(contentsOf: photoURL) else {
                return nil
            }
            return UIImage(data: data)
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
            savesDraft: metadata.savesDraft ?? true,
            isPrivate: metadata.isPrivate ?? false,
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
            photos: legacyDraft.photos,
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
    var artStyle: String?
    var location: String?
    var date: Date?
    var savesDraft: Bool?
    var isPrivate: Bool?
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
                image: image,
                promptText: item.promptText,
                artStyle: item.artStyle,
                sourcePhotoCount: item.sourcePhotoCount,
                createdAt: item.createdAt,
                imageFileName: item.imageFileName
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
                promptText: storyboard.promptText,
                artStyle: storyboard.artStyle,
                sourcePhotoCount: storyboard.sourcePhotoCount,
                createdAt: storyboard.createdAt,
                imageFileName: imageFileName
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
        promptText: String,
        artStyle: String,
        sourcePhotoCount: Int
    ) throws -> GeneratedStoryboard {
        try FileManager.default.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )

        let id = UUID()
        let imageFileName = "\(id.uuidString).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(imageFileName)

        guard let imageData = image.storytopiaPreparedJPEGData(compressionQuality: 0.9) else {
            throw StoryboardGenerationError.invalidRequest
        }

        try imageData.write(to: imageURL, options: [.atomic])

        return GeneratedStoryboard(
            id: id,
            image: image,
            promptText: promptText,
            artStyle: artStyle,
            sourcePhotoCount: sourcePhotoCount,
            imageFileName: imageFileName
        )
    }

    private static var imagesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GeneratedStoryboards", isDirectory: true)
    }
}

struct GeneratedStoryboardMetadata: Codable {
    let id: UUID
    let promptText: String
    let artStyle: String
    let sourcePhotoCount: Int
    let createdAt: Date
    let imageFileName: String
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

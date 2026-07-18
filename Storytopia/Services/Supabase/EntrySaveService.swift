import Foundation
import UIKit

enum EntryCloudSaveState: Equatable {
    case idle
    case saving
    case saved
    case savedLocally
    case uploadingPhotos
    case photosUploaded
    case failed(String)
    case photoUploadFailed(String)

    var message: String? {
        switch self {
        case .idle:
            return nil
        case .saving:
            return "Saving..."
        case .saved:
            return "Saved to Storytopia cloud."
        case .savedLocally:
            return "Saved locally. Sign in to save to Storytopia cloud."
        case .uploadingPhotos:
            return "Uploading photos..."
        case .photosUploaded:
            return "Photos uploaded."
        case .failed(let message):
            return message
        case .photoUploadFailed(let message):
            return message
        }
    }
}

struct EntryDraftSavePayload {
    let id: UUID?
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
    let fontChoiceRawValue: String
    let textColorIndex: Int
    let textSize: Double
    let paperStyleRawValue: String
    let paperColorIndex: Int
    let isBold: Bool
    let isItalic: Bool
    let isUnderlined: Bool
    let isStrikethrough: Bool
    let isHighlighted: Bool
    let textAlignmentRawValue: String
}

struct EntrySaveResult {
    let localDraftID: UUID
    let cloudEntry: JournalEntry?
    let state: EntryCloudSaveState
}

@MainActor
struct EntrySaveService {
    private let repository: SupabaseEntryRepository
    private let referencePhotoService: SupabaseReferencePhotoService

    init(
        repository: SupabaseEntryRepository = SupabaseEntryRepository(),
        referencePhotoService: SupabaseReferencePhotoService = SupabaseReferencePhotoService()
    ) {
        self.repository = repository
        self.referencePhotoService = referencePhotoService
    }

    func ensureEntryAndReferencePhotosSynced(
        payload: EntryDraftSavePayload,
        isSignedIn: Bool,
        status: JournalEntryStatus = .draft
    ) async throws -> EntrySaveResult {
        guard let localDraftID = persistLocalDraft(payload) else {
            throw JournalEntryRepositoryError.operationFailed
        }

        EntryLocationRecentStore.add(payload.location)

        guard isSignedIn else {
            return EntrySaveResult(
                localDraftID: localDraftID,
                cloudEntry: nil,
                state: .savedLocally
            )
        }

        let cloudEntry: JournalEntry
        do {
            cloudEntry = try await repository.upsertEntry(
                clientEntryID: localDraftID,
                title: payload.title,
                content: payload.text,
                richText: payload.richText,
                artStyle: payload.artStyle,
                location: payload.location,
                entryDate: payload.date,
                datePrecision: payload.datePrecision,
                savesDraft: payload.savesDraft,
                isPrivate: payload.isPrivate,
                fontChoiceRawValue: payload.fontChoiceRawValue,
                textColorIndex: payload.textColorIndex,
                textSize: payload.textSize,
                paperStyleRawValue: payload.paperStyleRawValue,
                paperColorIndex: payload.paperColorIndex,
                isBold: payload.isBold,
                isItalic: payload.isItalic,
                isUnderlined: payload.isUnderlined,
                isStrikethrough: payload.isStrikethrough,
                isHighlighted: payload.isHighlighted,
                textAlignmentRawValue: payload.textAlignmentRawValue,
                status: status
            )
        } catch {
            return EntrySaveResult(
                localDraftID: localDraftID,
                cloudEntry: nil,
                state: .failed("Saved locally. Cloud save failed.")
            )
        }

        do {
            try await referencePhotoService.syncReferencePhotos(
                entry: cloudEntry,
                photos: payload.photos
            )

            return EntrySaveResult(
                localDraftID: localDraftID,
                cloudEntry: cloudEntry,
                state: payload.photos.isEmpty ? .saved : .photosUploaded
            )
        } catch {
            return EntrySaveResult(
                localDraftID: localDraftID,
                cloudEntry: cloudEntry,
                state: .photoUploadFailed("Saved locally. Photo sync failed.")
            )
        }
    }

    func deleteEntry(localDraftID: UUID, cloudEntry: JournalEntry?, isSignedIn: Bool) async throws {
        guard let cloudEntry else {
            CreateEntryDraftStore.delete(id: localDraftID)
            return
        }

        guard isSignedIn else {
            throw JournalEntryRepositoryError.notAuthenticated
        }

        try await referencePhotoService.deleteReferencePhotos(entryID: cloudEntry.id)
        try await repository.deleteEntry(id: cloudEntry.id)
        CreateEntryDraftStore.delete(id: localDraftID)
    }

    func persistLocalDraft(_ payload: EntryDraftSavePayload) -> UUID? {
        let draftThumbnail = DraftThumbnailRenderer.render(
            title: payload.title,
            text: payload.text,
            richText: payload.richText,
            photos: payload.photos.map(\.image),
            fontChoiceRawValue: payload.fontChoiceRawValue,
            textColorIndex: payload.textColorIndex,
            textSize: payload.textSize,
            paperStyleRawValue: payload.paperStyleRawValue,
            paperColorIndex: payload.paperColorIndex,
            isBold: payload.isBold,
            isItalic: payload.isItalic,
            isUnderlined: payload.isUnderlined,
            isStrikethrough: payload.isStrikethrough,
            isHighlighted: payload.isHighlighted,
            textAlignmentRawValue: payload.textAlignmentRawValue
        )

        return CreateEntryDraftStore.save(
            id: payload.id,
            title: payload.title,
            text: payload.text,
            richText: payload.richText,
            referencePhotos: payload.photos,
            artStyle: payload.artStyle,
            location: payload.location,
            date: payload.date,
            datePrecision: payload.datePrecision,
            savesDraft: payload.savesDraft,
            isPrivate: payload.isPrivate,
            fontChoiceRawValue: payload.fontChoiceRawValue,
            textColorIndex: payload.textColorIndex,
            textSize: payload.textSize,
            paperStyleRawValue: payload.paperStyleRawValue,
            paperColorIndex: payload.paperColorIndex,
            isBold: payload.isBold,
            isItalic: payload.isItalic,
            isUnderlined: payload.isUnderlined,
            isStrikethrough: payload.isStrikethrough,
            isHighlighted: payload.isHighlighted,
            textAlignmentRawValue: payload.textAlignmentRawValue,
            thumbnail: draftThumbnail
        )
    }
}

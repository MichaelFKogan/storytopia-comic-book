import Foundation
import Supabase

struct JournalEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    let clientEntryID: UUID
    let title: String?
    let content: String?
    let status: String
    let richText: NotebookRichTextDocument?
    let artStyle: String?
    let location: String?
    let entryDate: Date?
    let datePrecision: String?
    let savesDraft: Bool?
    let isPrivate: Bool?
    let fontChoiceRawValue: String?
    let textColorIndex: Int?
    let textSize: Double?
    let paperStyleRawValue: String?
    let paperColorIndex: Int?
    let isBold: Bool?
    let isItalic: Bool?
    let isUnderlined: Bool?
    let isStrikethrough: Bool?
    let isHighlighted: Bool?
    let textAlignmentRawValue: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientEntryID = "client_entry_id"
        case title
        case content
        case status
        case richText = "rich_text"
        case artStyle = "art_style"
        case location
        case entryDate = "entry_date"
        case datePrecision = "date_precision"
        case savesDraft = "saves_draft"
        case isPrivate = "is_private"
        case fontChoiceRawValue = "font_choice_raw_value"
        case textColorIndex = "text_color_index"
        case textSize = "text_size"
        case paperStyleRawValue = "paper_style_raw_value"
        case paperColorIndex = "paper_color_index"
        case isBold = "is_bold"
        case isItalic = "is_italic"
        case isUnderlined = "is_underlined"
        case isStrikethrough = "is_strikethrough"
        case isHighlighted = "is_highlighted"
        case textAlignmentRawValue = "text_alignment_raw_value"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct JournalEntryPayload: Encodable, Sendable {
    let userID: UUID
    let clientEntryID: UUID
    let title: String?
    let content: String?
    let status: String
    let richText: NotebookRichTextDocument?
    let artStyle: String?
    let location: String?
    let entryDate: Date?
    let datePrecision: String?
    let savesDraft: Bool?
    let isPrivate: Bool?
    let fontChoiceRawValue: String?
    let textColorIndex: Int?
    let textSize: Double?
    let paperStyleRawValue: String?
    let paperColorIndex: Int?
    let isBold: Bool?
    let isItalic: Bool?
    let isUnderlined: Bool?
    let isStrikethrough: Bool?
    let isHighlighted: Bool?
    let textAlignmentRawValue: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientEntryID = "client_entry_id"
        case title
        case content
        case status
        case richText = "rich_text"
        case artStyle = "art_style"
        case location
        case entryDate = "entry_date"
        case datePrecision = "date_precision"
        case savesDraft = "saves_draft"
        case isPrivate = "is_private"
        case fontChoiceRawValue = "font_choice_raw_value"
        case textColorIndex = "text_color_index"
        case textSize = "text_size"
        case paperStyleRawValue = "paper_style_raw_value"
        case paperColorIndex = "paper_color_index"
        case isBold = "is_bold"
        case isItalic = "is_italic"
        case isUnderlined = "is_underlined"
        case isStrikethrough = "is_strikethrough"
        case isHighlighted = "is_highlighted"
        case textAlignmentRawValue = "text_alignment_raw_value"
    }
}

struct JournalEntryUpdate: Encodable, Sendable {
    let title: String?
    let content: String?
    let status: String?
}

enum JournalEntryStatus: String, Codable, Sendable {
    case draft
    case completed
    case archived
}

enum JournalEntryRepositoryError: LocalizedError {
    case notAuthenticated
    case emptyTitleAndContent
    case operationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in before editing entries."
        case .emptyTitleAndContent:
            return "Add a title or entry text first."
        case .operationFailed:
            return "The entry could not be saved. Please try again."
        }
    }
}

struct SupabaseEntryRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseService.shared) {
        self.client = client
    }

    func getEntries() async throws -> [JournalEntry] {
        let userID = try await authenticatedUserID()

        do {
            return try await client
                .from("entries")
                .select()
                .eq("user_id", value: userID)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            throw JournalEntryRepositoryError.operationFailed
        }
    }

    func getEntry(id: UUID) async throws -> JournalEntry {
        let userID = try await authenticatedUserID()

        do {
            return try await client
                .from("entries")
                .select()
                .eq("id", value: id)
                .eq("user_id", value: userID)
                .limit(1)
                .single()
                .execute()
                .value
        } catch {
            throw JournalEntryRepositoryError.operationFailed
        }
    }

    func createEntry(title: String, content: String) async throws -> JournalEntry {
        let userID = try await authenticatedUserID()
        let cleanTitle = title.trimmedOrNil
        let cleanContent = content.trimmedOrNil

        guard cleanTitle != nil || cleanContent != nil else {
            throw JournalEntryRepositoryError.emptyTitleAndContent
        }

        do {
            return try await client
                .from("entries")
                .insert(
                    JournalEntryPayload(
                        userID: userID,
                        clientEntryID: UUID(),
                        title: cleanTitle,
                        content: cleanContent,
                        status: "draft",
                        richText: nil,
                        artStyle: nil,
                        location: nil,
                        entryDate: nil,
                        datePrecision: nil,
                        savesDraft: nil,
                        isPrivate: nil,
                        fontChoiceRawValue: nil,
                        textColorIndex: nil,
                        textSize: nil,
                        paperStyleRawValue: nil,
                        paperColorIndex: nil,
                        isBold: nil,
                        isItalic: nil,
                        isUnderlined: nil,
                        isStrikethrough: nil,
                        isHighlighted: nil,
                        textAlignmentRawValue: nil
                    )
                )
                .select()
                .single()
                .execute()
                .value
        } catch {
            throw JournalEntryRepositoryError.operationFailed
        }
    }

    func updateEntry(id: UUID, title: String, content: String, status: JournalEntryStatus = .draft) async throws -> JournalEntry {
        let userID = try await authenticatedUserID()
        let cleanTitle = title.trimmedOrNil
        let cleanContent = content.trimmedOrNil

        guard cleanTitle != nil || cleanContent != nil else {
            throw JournalEntryRepositoryError.emptyTitleAndContent
        }

        do {
            return try await client
                .from("entries")
                .update(
                    JournalEntryUpdate(
                        title: cleanTitle,
                        content: cleanContent,
                        status: status.rawValue
                    )
                )
                .eq("id", value: id)
                .eq("user_id", value: userID)
                .select()
                .single()
                .execute()
                .value
        } catch {
            throw JournalEntryRepositoryError.operationFailed
        }
    }

    func upsertEntry(
        clientEntryID: UUID,
        title: String,
        content: String,
        richText: NotebookRichTextDocument? = nil,
        artStyle: String? = nil,
        location: String? = nil,
        entryDate: Date? = nil,
        datePrecision: EntryDatePrecision? = nil,
        savesDraft: Bool? = nil,
        isPrivate: Bool? = nil,
        fontChoiceRawValue: String? = nil,
        textColorIndex: Int? = nil,
        textSize: Double? = nil,
        paperStyleRawValue: String? = nil,
        paperColorIndex: Int? = nil,
        isBold: Bool? = nil,
        isItalic: Bool? = nil,
        isUnderlined: Bool? = nil,
        isStrikethrough: Bool? = nil,
        isHighlighted: Bool? = nil,
        textAlignmentRawValue: String? = nil,
        status: JournalEntryStatus = .draft
    ) async throws -> JournalEntry {
        let userID = try await authenticatedUserID()
        let cleanTitle = title.trimmedOrNil
        let cleanContent = content.trimmedOrNil

        guard cleanTitle != nil || cleanContent != nil else {
            throw JournalEntryRepositoryError.emptyTitleAndContent
        }

        do {
            return try await client
                .from("entries")
                .upsert(
                    JournalEntryPayload(
                        userID: userID,
                        clientEntryID: clientEntryID,
                        title: cleanTitle,
                        content: cleanContent,
                        status: status.rawValue,
                        richText: richText,
                        artStyle: artStyle?.trimmedOrNil,
                        location: location?.trimmedOrNil,
                        entryDate: entryDate,
                        datePrecision: datePrecision?.rawValue,
                        savesDraft: savesDraft,
                        isPrivate: isPrivate,
                        fontChoiceRawValue: fontChoiceRawValue?.trimmedOrNil,
                        textColorIndex: textColorIndex,
                        textSize: textSize,
                        paperStyleRawValue: paperStyleRawValue?.trimmedOrNil,
                        paperColorIndex: paperColorIndex,
                        isBold: isBold,
                        isItalic: isItalic,
                        isUnderlined: isUnderlined,
                        isStrikethrough: isStrikethrough,
                        isHighlighted: isHighlighted,
                        textAlignmentRawValue: textAlignmentRawValue?.trimmedOrNil
                    ),
                    onConflict: "user_id,client_entry_id"
                )
                .select()
                .single()
                .execute()
                .value
        } catch {
            throw JournalEntryRepositoryError.operationFailed
        }
    }

    func deleteEntry(clientEntryID: UUID) async throws {
        let userID = try await authenticatedUserID()

        do {
            try await client
                .from("entries")
                .delete()
                .eq("client_entry_id", value: clientEntryID)
                .eq("user_id", value: userID)
                .execute()
        } catch {
            throw JournalEntryRepositoryError.operationFailed
        }
    }

    func deleteEntry(id: UUID) async throws {
        let userID = try await authenticatedUserID()

        do {
            try await client
                .from("entries")
                .delete()
                .eq("id", value: id)
                .eq("user_id", value: userID)
                .execute()
        } catch {
            throw JournalEntryRepositoryError.operationFailed
        }
    }

    private func authenticatedUserID() async throws -> UUID {
        do {
            return try await client.auth.session.user.id
        } catch {
            throw JournalEntryRepositoryError.notAuthenticated
        }
    }
}

private extension String {
    var trimmedOrNil: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

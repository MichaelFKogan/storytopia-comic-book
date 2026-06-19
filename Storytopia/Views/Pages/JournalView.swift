import SwiftUI
import UIKit

struct JournalView: View {
    @Binding var selectedPage: StoryPage
    @Binding var isDraftSaved: Bool
    @Binding var activeDraftID: UUID?

    @State private var searchText = ""
    @State private var showsPrototypeData = true
    @State private var chapters: [PrototypeChapter]
    @State private var savedDrafts: [CreateEntryDraft]

    init(
        selectedPage: Binding<StoryPage>,
        isDraftSaved: Binding<Bool>,
        activeDraftID: Binding<UUID?>
    ) {
        _selectedPage = selectedPage
        _isDraftSaved = isDraftSaved
        _activeDraftID = activeDraftID
        _savedDrafts = State(initialValue: CreateEntryDraftStore.loadAll())
        _chapters = State(initialValue: DailyJournalData.allChapters())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                journalBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        header

                        if showsPrototypeData {
                            prototypeNotice
                            chapterList
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 92)
                }

                BottomNavigationBar(selectedPage: $selectedPage)

            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            savedDrafts = CreateEntryDraftStore.loadAll()
            isDraftSaved = !savedDrafts.isEmpty
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Journals")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()
        }
        .padding(.top, 12)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.homeMutedText.opacity(0.76))

            TextField("Search entries...", text: $searchText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.storyInk)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.homeMutedText.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 39)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
    }

    private var savedDraftsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                Text("Saved Drafts")
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                if !savedDrafts.isEmpty {
                    NavigationLink {
                        SavedDraftsView(
                            selectedPage: $selectedPage,
                            activeDraftID: $activeDraftID
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Text("View All")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.homeAccent)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let mostRecentDraft {
                savedDraftCard(mostRecentDraft)
            } else if !savedDrafts.isEmpty {
                noDraftSearchResults
            } else {
                noSavedDrafts
            }
        }
        .padding(.top, 2)
    }

    private func savedDraftCard(_ draft: CreateEntryDraft) -> some View {
        Button {
            activeDraftID = draft.id
            selectedPage = .create
        } label: {
            HStack(spacing: 12) {
                draftThumbnail(draft)

                VStack(alignment: .leading, spacing: 5) {
                    Text(draftDisplayTitle(draft))
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)
                        .lineLimit(1)

                    Text(draftPreviewText(draft))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.storyInk.opacity(0.66))
                        .lineLimit(2)

                    HStack(spacing: 5) {
                        Image(systemName: "pencil.line")
                        Text("Continue writing")

                        if !draft.photos.isEmpty {
                            Text("•")
                            Image(systemName: "photo")
                            Text("\(draft.photos.count)")
                        }
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.homeAccent)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.homeMutedText.opacity(0.52))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.homeBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func deleteDraft(_ draft: CreateEntryDraft) {
        CreateEntryDraftStore.delete(id: draft.id)
        savedDrafts.removeAll { $0.id == draft.id }
        if activeDraftID == draft.id {
            activeDraftID = nil
        }
        isDraftSaved = !savedDrafts.isEmpty
    }

    @ViewBuilder
    private func draftThumbnail(_ draft: CreateEntryDraft) -> some View {
        if let image = draft.photos.first {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.homeAccent.opacity(0.1))
                .frame(width: 58, height: 70)
                .overlay {
                    Image(systemName: "doc.text")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.homeAccent)
                }
        }
    }

    private var noSavedDrafts: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 20))
                .foregroundStyle(Color.homeAccent.opacity(0.7))

            Text("Drafts you save while creating a story will appear here.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.homeMutedText)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
    }

    private var noDraftSearchResults: some View {
        Text("No saved drafts match your search.")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.homeMutedText)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.homeBorder, lineWidth: 1)
            )
    }

    private func draftDisplayTitle(_ draft: CreateEntryDraft) -> String {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "Untitled Draft" : trimmedTitle
    }

    private func draftPreviewText(_ draft: CreateEntryDraft) -> String {
        let trimmedText = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            return trimmedText
        }
        if !draft.photos.isEmpty {
            return draft.photos.count == 1 ? "1 reference photo" : "\(draft.photos.count) reference photos"
        }
        return "Draft ready to continue"
    }

    private var filteredDrafts: [CreateEntryDraft] {
        savedDrafts.filter { draft in
            searchText.isEmpty
                || draftDisplayTitle(draft).localizedCaseInsensitiveContains(searchText)
                || draft.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var mostRecentDraft: CreateEntryDraft? {
        filteredDrafts.first
    }

    private var prototypeNotice: some View {
        HStack(spacing: 9) {
            Image(systemName: "eye.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.homeAccent)

            Text("Previewing sample journal entries")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.homeMutedText)

            Spacer()

            Button("Show empty") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsPrototypeData = false
                }
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.homeAccent)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
    }

    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .lastTextBaseline) {
                Text("Your Journals")
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Text("\(chapters.count) days")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)
            }
            .padding(.top, 2)

            if chapters.isEmpty {
                noSearchResults
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                        NavigationLink {
                            dailyJournalDetail(for: chapter, dayOffset: index)
                        } label: {
                            PrototypeChapterRow(
                                chapter: DailyJournalData.dateTitledChapter(from: chapter, dayOffset: index),
                                date: journalDate(dayOffset: index)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func journalDate(dayOffset: Int) -> Date {
        DailyJournalData.journalDate(dayOffset: dayOffset)
    }

    private func dailyJournalDetail(for chapter: PrototypeChapter, dayOffset: Int) -> some View {
        DailyJournalData.detailView(for: chapter, dayOffset: dayOffset) { entry in
            guard let chapterIndex = chapters.firstIndex(where: { $0.id == chapter.id }) else {
                return
            }

            chapters[chapterIndex].entries.insert(entry, at: 0)
            StoryEntryStore.add(entry, to: chapter.title)
        }
    }

    private var noSearchResults: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(Color.homeAccent.opacity(0.6))

            Text("No journals yet")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Text("Your journals will appear here.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.homeMutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 58)

            Image("no_entries_journal")
                .resizable()
                .scaledToFit()
                .frame(width: 165)
                .padding(.bottom, 3)

            VStack(spacing: 8) {
                Text("No entries yet")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.storyInk)

                Text("Your journal will appear here\nonce you start writing.")
                    .font(.system(size: 13, weight: .semibold))
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.homeMutedText)
            }

            Button {
                selectedPage = .create
            } label: {
                Label("Write Your First Entry", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 39)
                    .background(Color.homeAccent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.top, 10)

            Button("Preview sample chapters") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsPrototypeData = true
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.homeAccent)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private var journalBackground: some View {
        Color.homePageBackground
            .ignoresSafeArea()
    }
}

struct DaybookView: View {
    @Binding var selectedPage: StoryPage
    @State private var chapters = DailyJournalData.allChapters()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.homePageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Daybook")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(Color.storyInk)
                            .padding(.top, 12)

                        AllJournalEntriesSection(chapters: $chapters)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 92)
                }

                BottomNavigationBar(selectedPage: $selectedPage)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            chapters = DailyJournalData.allChapters()
        }
    }
}

private enum DailyJournalData {
    static func allChapters() -> [PrototypeChapter] {
        let visibleSamples = PrototypeChapter.samples.filter {
            !DeletedSampleChapterStore.contains(title: $0.title)
        }
        let chapters = UserChapterStore.load() + visibleSamples
        return chapters.map(chapterWithStoredEntries)
    }

    static func journalDate(dayOffset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
    }

    static func dateTitledChapter(from chapter: PrototypeChapter, dayOffset: Int) -> PrototypeChapter {
        let date = journalDate(dayOffset: dayOffset)
        return PrototypeChapter(
            title: Calendar.current.isDateInToday(date)
                ? "Today"
                : date.formatted(.dateTime.weekday(.wide)),
            subtitle: date.formatted(date: .complete, time: .omitted),
            color: chapter.color,
            symbol: "calendar",
            coverImageName: chapter.coverImageName,
            kind: .journal,
            isFavorite: chapter.isFavorite,
            entries: chapter.entries
        )
    }

    static func detailView(
        for chapter: PrototypeChapter,
        dayOffset: Int,
        onNewEntryPresentationChange: @escaping (Bool) -> Void = { _ in },
        onAddEntry: @escaping (PrototypeEntry) -> Void
    ) -> some View {
        PrototypeChapterDetailView(
            chapter: dateTitledChapter(from: chapter, dayOffset: dayOffset),
            entryDate: journalDate(dayOffset: dayOffset),
            presentation: .dailyJournal,
            onNewEntryPresentationChange: onNewEntryPresentationChange,
            onCreateStory: onAddEntry
        )
    }

    private static func chapterWithStoredEntries(_ chapter: PrototypeChapter) -> PrototypeChapter {
        var chapter = chapter
        chapter.entries = StoryEntryStore.load(for: chapter.title) + chapter.entries
        return chapter
    }
}

private struct DailyJournalEntrySummary: Identifiable {
    let dayOffset: Int
    let chapter: PrototypeChapter
    let entry: PrototypeEntry
    let coverImageName: String?

    var id: UUID {
        entry.id
    }
}

private struct AllJournalEntriesSection: View {
    @Binding var chapters: [PrototypeChapter]

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .lastTextBaseline) {
                Text("All Entries")
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Text(allJournalEntriesCountText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)
            }
            .padding(.top, 6)

            if allJournalEntries.isEmpty {
                noJournalEntries
            } else {
                LazyVStack(spacing: 18) {
                    ForEach(allJournalEntryDays) { day in
                        journalDayGroup(day)
                    }
                }
            }
        }
    }

    private func journalDayGroup(_ day: DailyJournalDaySummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                dailyJournalDetail(for: day.sourceChapter, dayOffset: day.dayOffset)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    journalDateBadge(day)
                    journalDayHeader(day)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open journal for \(day.fullDateText)")

            ForEach(Array(day.entries.enumerated()), id: \.element.id) { index, item in
                NavigationLink {
                    PrototypeEntryDetailView(
                        entry: item.entry,
                        chapter: item.chapter,
                        title: "Journal Entry"
                    )
                } label: {
                    PrototypeEntryRow(
                        entry: regularPhotoDisplayEntry(for: item.entry, dayOffset: day.dayOffset, entryIndex: index),
                        accentColor: Color.homeAccent,
                        showsDate: false,
                        thumbnailSize: 48,
                        leadingCoverImageName: item.coverImageName,
                        showsReferencePhotos: false
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.homeBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func regularPhotoDisplayEntry(
        for entry: PrototypeEntry,
        dayOffset: Int,
        entryIndex: Int
    ) -> PrototypeEntry {
        guard !entry.imageNames.isEmpty else {
            return entry
        }

        return entry.copy(
            imageNames: regularPhotoNames(
                startIndex: (dayOffset * 3) + (entryIndex * 2),
                count: entry.imageNames.count
            )
        )
    }

    private func regularPhotoNames(startIndex: Int, count: Int) -> [String] {
        (0..<count).map { offset in
            regularSetImageNames[(startIndex + offset) % regularSetImageNames.count]
        }
    }

    private func journalDateBadge(_ day: DailyJournalDaySummary) -> some View {
        VStack(spacing: 0) {
            Text(day.monthText)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            Text(day.dayText)
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 43, height: 52)
        .background(
            LinearGradient(
                colors: [Color.homeAccent, Color.homeAccent.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
        )
        .shadow(color: Color.homeAccent.opacity(0.22), radius: 5, y: 3)
    }

    private func journalDayHeader(_ day: DailyJournalDaySummary) -> some View {
        HStack(spacing: 10) {
            Text(day.fullDateText)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.homeMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Rectangle()
                .fill(Color.homeBorder)
                .frame(height: 1)

            Text(day.entryCountText)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.homeMutedText)
                .lineLimit(1)

            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.homeAccent.opacity(0.72))
                .accessibilityHidden(true)
        }
        .frame(height: 27)
        .frame(maxWidth: .infinity)
    }

    private var noJournalEntries: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.pages")
                .font(.system(size: 28))
                .foregroundStyle(Color.homeAccent.opacity(0.68))

            Text("No journal entries yet")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Text("Entries from every day will appear here.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.homeMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var allJournalEntries: [DailyJournalEntrySummary] {
        allJournalEntryDays.flatMap(\.entries)
    }

    private var allJournalEntryDays: [DailyJournalDaySummary] {
        var nextStoryboardCoverIndex = 0

        return chapters.enumerated().compactMap { dayOffset, chapter -> DailyJournalDaySummary? in
            let datedChapter = DailyJournalData.dateTitledChapter(from: chapter, dayOffset: dayOffset)
            let entries = datedChapter.entries.map { entry in
                let coverImageName = storyboardExampleImageName(for: nextStoryboardCoverIndex)
                nextStoryboardCoverIndex += 1

                return DailyJournalEntrySummary(
                    dayOffset: dayOffset,
                    chapter: datedChapter,
                    entry: entry,
                    coverImageName: coverImageName
                )
            }

            guard !entries.isEmpty else {
                return nil
            }

            return DailyJournalDaySummary(
                dayOffset: dayOffset,
                sourceChapter: chapter,
                chapter: datedChapter,
                entries: entries
            )
        }
    }

    private var allJournalEntriesCountText: String {
        let count = allJournalEntries.count
        return "\(count) \(count == 1 ? "entry" : "entries")"
    }

    private var regularSetImageNames: [String] {
        [
            "IMG_9080",
            "IMG_9144",
            "IMG_2390",
            "IMG_2382 2",
            "IMG_9131",
            "IMG_9113",
            "IMG_9127",
            "IMG_9126",
            "IMG_9114",
            "IMG_9102",
            "IMG_2385 2",
            "IMG_9140",
            "IMG_2214"
        ]
    }

    private var storyboardExampleImageNames: [String] {
        (1...16).map { "storyboard\($0)" }
    }

    private func storyboardExampleImageName(for index: Int) -> String? {
        guard storyboardExampleImageNames.indices.contains(index) else {
            return nil
        }

        return storyboardExampleImageNames[index]
    }

    private func dailyJournalDetail(for chapter: PrototypeChapter, dayOffset: Int) -> some View {
        DailyJournalData.detailView(for: chapter, dayOffset: dayOffset) { entry in
            guard let chapterIndex = chapters.firstIndex(where: { $0.id == chapter.id }) else {
                return
            }

            chapters[chapterIndex].entries.insert(entry, at: 0)
            StoryEntryStore.add(entry, to: chapter.title)
        }
    }
}

private struct DailyJournalDaySummary: Identifiable {
    let dayOffset: Int
    let sourceChapter: PrototypeChapter
    let chapter: PrototypeChapter
    let entries: [DailyJournalEntrySummary]

    var id: Int {
        dayOffset
    }

    var monthText: String {
        date.formatted(.dateTime.month(.abbreviated)).uppercased()
    }

    var dayText: String {
        date.formatted(.dateTime.day())
    }

    var fullDateText: String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    var entryCountText: String {
        "\(entries.count) \(entries.count == 1 ? "entry" : "entries")"
    }

    private var date: Date {
        DailyJournalData.journalDate(dayOffset: dayOffset)
    }
}

private struct SavedDraftsView: View {
    @Binding var selectedPage: StoryPage
    @Binding var activeDraftID: UUID?

    @State private var drafts: [CreateEntryDraft] = []
    @State private var searchText = ""
    @State private var isEditingDrafts = false
    @State private var selectedDraftIDs: Set<UUID> = []
    @State private var isConfirmingSelectedDeletion = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.storyCream, .white, Color.storyBlush],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .lastTextBaseline) {
                        Text("Saved Drafts")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color.storyInk)

                        Spacer()

                        Text("\(drafts.count) \(drafts.count == 1 ? "draft" : "drafts")")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.storyGray)
                    }

                    draftSearchField

                    if filteredDrafts.isEmpty {
                        emptyDraftsState
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredDrafts) { draft in
                                Button {
                                    if isEditingDrafts {
                                        toggleSelection(draft.id)
                                    } else {
                                        activeDraftID = draft.id
                                        selectedPage = .create
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        if isEditingDrafts {
                                            Image(systemName: selectedDraftIDs.contains(draft.id) ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundStyle(
                                                    selectedDraftIDs.contains(draft.id)
                                                        ? Color.storyPurple
                                                        : Color.storyGray.opacity(0.55)
                                                )
                                        }

                                        SavedDraftRow(draft: draft)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color.storyCream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    if isEditingDrafts {
                        Button(role: .destructive) {
                            isConfirmingSelectedDeletion = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(selectedDraftIDs.isEmpty)
                    }

                    Button(isEditingDrafts ? "Done" : "Edit") {
                        isEditingDrafts.toggle()
                        if !isEditingDrafts {
                            selectedDraftIDs.removeAll()
                        }
                    }
                }
            }
        }
        .onAppear {
            drafts = CreateEntryDraftStore.loadAll()
        }
        .alert("Delete Selected Drafts?", isPresented: $isConfirmingSelectedDeletion) {
            Button("Delete", role: .destructive) {
                deleteSelectedDrafts()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(selectedDraftIDs.count) selected \(selectedDraftIDs.count == 1 ? "draft" : "drafts") will be permanently deleted.")
        }
    }

    private var draftSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.storyGray.opacity(0.76))

            TextField("Search drafts...", text: $searchText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.storyInk)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.storyGray.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.48), lineWidth: 1)
        )
    }

    private var emptyDraftsState: some View {
        VStack(spacing: 10) {
            Image(systemName: searchText.isEmpty ? "doc.badge.plus" : "text.magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(Color.storyPurple.opacity(0.65))

            Text(searchText.isEmpty ? "No saved drafts" : "No matching drafts")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Text(searchText.isEmpty ? "Drafts you save will appear here." : "Try another search.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.storyGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var filteredDrafts: [CreateEntryDraft] {
        drafts.filter { draft in
            searchText.isEmpty
                || draftDisplayTitle(draft).localizedCaseInsensitiveContains(searchText)
                || draft.text.localizedCaseInsensitiveContains(searchText)
                || draft.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func deleteDraft(_ draft: CreateEntryDraft) {
        CreateEntryDraftStore.delete(id: draft.id)
        drafts.removeAll { $0.id == draft.id }
        if activeDraftID == draft.id {
            activeDraftID = nil
        }
    }

    private func toggleSelection(_ draftID: UUID) {
        if selectedDraftIDs.contains(draftID) {
            selectedDraftIDs.remove(draftID)
        } else {
            selectedDraftIDs.insert(draftID)
        }
    }

    private func deleteSelectedDrafts() {
        drafts
            .filter { selectedDraftIDs.contains($0.id) }
            .forEach(deleteDraft)
        selectedDraftIDs.removeAll()
        isEditingDrafts = false
    }
}

private struct SavedDraftRow: View {
    let draft: CreateEntryDraft

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 5) {
                Text(draftDisplayTitle(draft))
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(1)

                Text(draftPreviewText(draft))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.storyInk.opacity(0.66))
                    .lineLimit(2)

                HStack(spacing: 5) {
                    Text("Edited \(draft.updatedAt.formatted(date: .abbreviated, time: .omitted))")

                    if !draft.photos.isEmpty {
                        Text("•")
                        Image(systemName: "photo")
                        Text("\(draft.photos.count)")
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.storyPurple)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.storyGray.opacity(0.52))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.storyPurple.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = draft.photos.first {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.storyLavender.opacity(0.72))
                .frame(width: 58, height: 70)
                .overlay {
                    Image(systemName: "doc.text")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.storyPurple)
                }
        }
    }
}

private func draftDisplayTitle(_ draft: CreateEntryDraft) -> String {
    let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedTitle.isEmpty ? "Untitled Draft" : trimmedTitle
}

private func draftPreviewText(_ draft: CreateEntryDraft) -> String {
    let trimmedText = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedText.isEmpty {
        return trimmedText
    }
    if !draft.photos.isEmpty {
        return draft.photos.count == 1 ? "1 reference photo" : "\(draft.photos.count) reference photos"
    }
    return "Draft ready to continue"
}

private struct PrototypeChapterRow: View {
    let chapter: PrototypeChapter
    let date: Date

    private var coverImageName: String? {
        chapter.entries.flatMap(\.imageNames).first ?? chapter.coverImageName
    }

    private var badgeMonth: String {
        date.formatted(.dateTime.month(.abbreviated)).uppercased()
    }

    private var badgeDay: String {
        date.formatted(.dateTime.day())
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            coverArt(width: width, height: width * 1.34)
                .frame(width: width, height: width * 1.34, alignment: .topLeading)
        }
        .aspectRatio(0.74, contentMode: .fit)
    }

    private func coverArt(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            if let coverImageName {
                Image(coverImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .overlay(
                        Rectangle()
                            .stroke(Color.storyInk.opacity(0.18), lineWidth: 1)
                    )
                    .accessibilityLabel("Journal cover image for \(badgeMonth) \(badgeDay)")
            } else {
                NotebookCover(
                    color: Color.homeAccent,
                    symbol: chapter.symbol,
                    imageName: nil,
                    width: width,
                    height: height
                )
                .accessibilityLabel("Notebook cover for \(badgeMonth) \(badgeDay)")
            }

            VStack(spacing: 1) {
                Text(badgeMonth)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                Text(badgeDay)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(
                LinearGradient(
                    colors: [Color.homeAccent, Color.homeAccent.opacity(0.84)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Rectangle()
                    .stroke(.white.opacity(0.38), lineWidth: 1)
            )
            .shadow(color: Color.homeAccent.opacity(0.28), radius: 4, y: 2)
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }

}

private struct NotebookCover: View {
    let color: Color
    let symbol: String
    let imageName: String?
    var width: CGFloat = 48
    var height: CGFloat = 58

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(color)

            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.12))
                    .clipped()
            }

            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            HStack {
                Rectangle()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 4)

                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 1)

                Spacer()
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.25), radius: 5, y: 3)
    }
}

private struct PrototypeChapterDetailView: View {
    enum Presentation {
        case story
        case dailyJournal
    }

    @State private var chapter: PrototypeChapter
    let onCreateStory: (PrototypeEntry) -> Void
    let onNewEntryPresentationChange: (Bool) -> Void
    let entryDate: Date
    let presentation: Presentation

    @State private var selectedSection = "Media"
    @State private var isShowingNewStory = false
    @State private var selectedMediaIndex: Int?

    private let sections = ["Entries", "Media"]

    private var mediaImageNames: [String] {
        chapter.entries.flatMap(\.imageNames)
    }

    private var heroImageName: String? {
        mediaImageNames.first ?? chapter.coverImageName
    }

    init(
        chapter: PrototypeChapter,
        entryDate: Date = Date(),
        presentation: Presentation = .story,
        onNewEntryPresentationChange: @escaping (Bool) -> Void = { _ in },
        onCreateStory: @escaping (PrototypeEntry) -> Void
    ) {
        _chapter = State(initialValue: chapter)
        _selectedSection = State(initialValue: presentation == .dailyJournal ? "Entries" : "Media")
        self.entryDate = entryDate
        self.presentation = presentation
        self.onNewEntryPresentationChange = onNewEntryPresentationChange
        self.onCreateStory = onCreateStory
    }

    var body: some View {
        ZStack {
            Color.homePageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        journalHeroHeader

                        VStack(alignment: .leading, spacing: 16) {
                            mediaComicStrip
                            sectionPicker

                            if selectedSection == "Entries" {
                                entriesList
                            } else {
                                mediaGrid
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .navigationTitle(chapter.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color.homePageBackground, for: .navigationBar)
        .tint(Color.homeAccent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingNewStory = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                }
                .accessibilityLabel(presentation == .dailyJournal ? "Create a new journal entry" : "Create a new story")
            }
        }
        .navigationDestination(isPresented: $isShowingNewStory) {
            NewStorySheet(
                chapterTitle: chapter.title,
                accentColor: Color.homeAccent,
                initialDate: entryDate,
                collectionLabel: presentation == .dailyJournal ? "Daily Journal" : "Chapter",
                locksEntryDate: presentation == .dailyJournal
            ) { entry in
                chapter.entries.insert(entry, at: 0)
                selectedSection = "Entries"
                onCreateStory(entry)
            }
        }
        .onChange(of: isShowingNewStory) { isShowing in
            onNewEntryPresentationChange(isShowing)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { selectedMediaIndex != nil },
                set: { isPresented in
                    if !isPresented {
                        selectedMediaIndex = nil
                    }
                }
            )
        ) {
            if let selectedMediaIndex {
                VerticalComicViewer(
                    imageNames: mediaImageNames,
                    initialIndex: selectedMediaIndex,
                    accentColor: Color.homeAccent
                )
            }
        }
    }

    private var journalHeroHeader: some View {
        heroDetails
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
    }

    private var heroDetails: some View {
        HStack(alignment: .bottom, spacing: 18) {
            NotebookCover(
                color: Color.homeAccent,
                symbol: chapter.symbol,
                imageName: heroImageName,
                width: 122,
                height: 158
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 12, y: 7)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Label(entryCountText, systemImage: "book.pages.fill")
                    Label("\(chapter.imageCount) photos", systemImage: "photo.fill")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.homeMutedText)
                .lineLimit(1)

                Text(chapter.title)
                    .font(.system(size: 30, weight: .heavy, design: .serif))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(chapter.subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)
                    .lineLimit(2)

                Text(entryDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.homeMutedText.opacity(0.78))
            }
        }
    }

    private var mediaComicStrip: some View {
        Group {
            if !mediaImageNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(mediaImageNames.enumerated()), id: \.offset) { index, imageName in
                            Button {
                                selectedMediaIndex = index
                            } label: {
                                comicStripPanel(imageName: imageName, index: index)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open photo \(index + 1) of \(mediaImageNames.count)")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, -16)
            }
        }
    }

    private func comicStripPanel(imageName: String, index: Int) -> some View {
        let size = comicStripPanelSize(for: imageName)

        return Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .topLeading) {
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.storyInk)
                    .frame(width: 24, height: 20)
                    .background(Color.white.opacity(0.9))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 6,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 5,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.white, lineWidth: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.storyInk.opacity(0.16), lineWidth: 1)
            )
            .rotationEffect(.degrees(comicStripRotation(for: index)))
            .shadow(color: Color.storyInk.opacity(0.12), radius: 7, y: 4)
            .padding(.vertical, 4)
    }

    private func comicStripPanelSize(for imageName: String) -> CGSize {
        let height: CGFloat = 248

        guard let image = UIImage(named: imageName), image.size.height > 0 else {
            return CGSize(width: 184, height: height)
        }

        let width = height * (image.size.width / image.size.height)
        return CGSize(width: min(max(width, 152), 308), height: height)
    }

    private func comicStripRotation(for index: Int) -> Double {
        switch index % 5 {
        case 0:
            return -1.5
        case 1:
            return 1.2
        case 2:
            return -0.6
        case 3:
            return 1.6
        default:
            return 0.4
        }
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(sections, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedSection = section
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(section)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(selectedSection == section ? Color.homeAccent : Color.homeMutedText.opacity(0.78))

                        Capsule()
                            .fill(selectedSection == section ? Color.homeAccent : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    private var entriesList: some View {
        Group {
            if chapter.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.homeAccent.opacity(0.72))

                    Text(presentation == .dailyJournal ? "No journal entries yet" : "No stories yet")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)

                    Text(
                        presentation == .dailyJournal
                            ? "Capture the first moment from this day."
                            : "Begin this chapter with its first story."
                    )
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                        .multilineTextAlignment(.center)

                    Button {
                        isShowingNewStory = true
                    } label: {
                        Label(
                            presentation == .dailyJournal ? "Write the First Entry" : "Write the First Story",
                            systemImage: "plus"
                        )
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 40)
                            .background(Color.homeAccent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(chapter.entries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            PrototypeEntryDetailView(
                                entry: entry,
                                chapter: chapter,
                                title: presentation == .dailyJournal ? "Journal Entry" : "Story"
                            )
                        } label: {
                            PrototypeEntryRow(entry: entry, accentColor: Color.homeAccent)
                        }
                        .buttonStyle(.plain)

                        if index < chapter.entries.count - 1 {
                            Divider()
                                .padding(.leading, 54)
                        }
                    }
                }
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var entryCountText: String {
        let noun: String
        if presentation == .dailyJournal {
            noun = chapter.entries.count == 1 ? "entry" : "entries"
        } else {
            noun = chapter.entries.count == 1 ? "story" : "stories"
        }
        return "\(chapter.entries.count) \(noun)"
    }

    private var mediaGrid: some View {
        Group {
            if mediaImageNames.isEmpty {
                Text("No photos yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(Array(mediaImageNames.enumerated()), id: \.offset) { index, imageName in
                        Button {
                            selectedMediaIndex = index
                        } label: {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open photo \(index + 1) of \(mediaImageNames.count)")
                    }
                }
            }
        }
    }
}

private struct NewStorySheet: View {
    let chapterTitle: String
    let accentColor: Color
    let collectionLabel: String
    let locksEntryDate: Bool
    let onCreate: (PrototypeEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var location = ""
    @State private var storyDate: Date
    @State private var isPrivateEntry = false
    @State private var isShowingExpandedEditor = false
    @FocusState private var isTitleFocused: Bool
    @State private var editorFocusRequestID = 0

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBody: String {
        bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(
        chapterTitle: String,
        accentColor: Color,
        initialDate: Date = Date(),
        collectionLabel: String = "Chapter",
        locksEntryDate: Bool = false,
        onCreate: @escaping (PrototypeEntry) -> Void
    ) {
        self.chapterTitle = chapterTitle
        self.accentColor = accentColor
        self.collectionLabel = collectionLabel
        self.locksEntryDate = locksEntryDate
        self.onCreate = onCreate
        _storyDate = State(initialValue: initialDate)
    }

    var body: some View {
        ZStack {
            newStoryBackground
                .onTapGesture {
                    dismissKeyboard()
                }

            VStack(alignment: .leading, spacing: 0) {
                pageHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        editorCard
                        storyDetailsCard
                        entryPrivacyCard
                        saveEntryButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isShowingExpandedEditor) {
            ExpandedEntryEditor(entryText: $bodyText, storyTitle: $title)
        }
        .background(newStoryBackground)
        .preferredColorScheme(.light)
    }

    private var pageHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                dismissKeyboard()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.storyInk.opacity(0.72))
                    .frame(width: 34, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Text("New Entry")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(Color.storyGray.opacity(0.46))

            Spacer()

            Button {
                createStory()
            } label: {
                Text("Save")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .disabled(trimmedTitle.isEmpty || trimmedBody.isEmpty)
            .opacity(trimmedTitle.isEmpty || trimmedBody.isEmpty ? 0.42 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var newStoryBackground: some View {
        ZStack {
            Color.storyCream

            LinearGradient(
                colors: [
                    accentColor.opacity(0.22),
                    Color.storyCream,
                    Color.storyBlush.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var editorCard: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                ZStack(alignment: .topLeading) {
                    NotebookPaperBackground(
                        showsPaperWash: false,
                        showsRuledLines: true,
                        firstRuledLineY: NotebookMetrics.firstNotebookRuleY
                    )
                    .frame(maxWidth: .infinity, minHeight: 504, maxHeight: .infinity)

                    NotebookEditorContent(
                        storyTitle: $title,
                        entryText: $bodyText,
                        isTitleFocused: $isTitleFocused,
                        editorFocusRequestID: editorFocusRequestID,
                        bodyPlaceholder: "Start writing...",
                        scrollsInternally: false,
                        pageHeight: 504,
                        onTitleSubmit: {
                            editorFocusRequestID += 1
                        }
                    )
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 504)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(height: 504)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .notebookPageChrome()
        .overlay(alignment: .bottomTrailing) {
            Button {
                dismissKeyboard()
                isShowingExpandedEditor = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 34, height: 34)
                    .background(accentColor.opacity(0.1), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(0.26), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Expand to full page")
            .padding(8)
        }
        .padding(.horizontal, -16)
    }

    private var storyDetailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Story Details")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)

            HStack(spacing: 12) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 20)

                Text(collectionLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.storyInk.opacity(0.9))
                    .frame(width: 90, alignment: .leading)

                Text(chapterTitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)

            Divider()
                .padding(.leading, 44)

            storyTextFieldRow

            Divider()
                .padding(.leading, 44)

            DatePicker(
                selection: $storyDate,
                displayedComponents: locksEntryDate ? [.hourAndMinute] : [.date, .hourAndMinute]
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accentColor)
                        .frame(width: 20)

                    Text("Date/time")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.storyInk.opacity(0.9))
                }
            }
            .font(.system(size: 13, weight: .medium))
            .tint(accentColor)
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

    private var storyTextFieldRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "location")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 20)

            Text("Location")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.storyInk.opacity(0.9))
                .frame(width: 72, alignment: .leading)

            TextField("Add a location", text: $location)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.storyInk)
                .tint(accentColor)
                .textInputAutocapitalization(.words)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
    }

    private var entryPrivacyCard: some View {
        Toggle(isOn: $isPrivateEntry) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Private Entry")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.storyInk)

                    Text("Only you can see this entry")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: accentColor))
        .padding(.horizontal, 12)
        .frame(height: 58)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }

    private var saveEntryButton: some View {
        Button {
            createStory()
        } label: {
            HStack(spacing: 7) {
                Text("Save Entry")
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [accentColor.opacity(0.92), accentColor],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .shadow(color: accentColor.opacity(0.18), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(trimmedTitle.isEmpty || trimmedBody.isEmpty)
        .opacity(trimmedTitle.isEmpty || trimmedBody.isEmpty ? 0.48 : 1)
        .padding(.top, 2)
    }

    private func dismissKeyboard() {
        isTitleFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func createStory() {
        guard !trimmedTitle.isEmpty, !trimmedBody.isEmpty else {
            return
        }

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        onCreate(
            PrototypeEntry(
                weekday: weekdayFormatter.string(from: storyDate).uppercased(),
                day: dayFormatter.string(from: storyDate),
                title: trimmedTitle,
                body: trimmedBody,
                time: timeFormatter.string(from: storyDate),
                location: trimmedLocation.isEmpty ? nil : trimmedLocation,
                imageNames: []
            )
        )
        dismiss()
    }
}

private struct PrototypeEntryDetailView: View {
    let entry: PrototypeEntry
    let chapter: PrototypeChapter
    let title: String

    @State private var isFavorite = false
    @State private var selectedImageName: String?

    var body: some View {
        ZStack {
            storyDetailBackground

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if !entry.imageNames.isEmpty {
                            photoStory
                        }

                        entryIntroduction
                        journalPage
                        entryDetails
                        referencePhotosSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
                }
                .background(Color.clear)
            }
        }
        .background(storyDetailBackground)
        .preferredColorScheme(.light)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color.homePageBackground, for: .navigationBar)
        .tint(Color.homeAccent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                entryOptionsMenu
            }
        }
        .sheet(
            isPresented: Binding(
                get: { selectedImageName != nil },
                set: { isPresented in
                    if !isPresented {
                        selectedImageName = nil
                    }
                }
            )
        ) {
            if let selectedImageName {
                PhotoViewer(imageName: selectedImageName, accentColor: Color.homeAccent)
            }
        }
    }

    private var storyDetailBackground: some View {
        Color.homePageBackground
            .ignoresSafeArea()
    }

    private var entryOptionsMenu: some View {
        Menu {
            Button {
                isFavorite.toggle()
            } label: {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "heart.slash" : "heart"
                )
            }

            Button {
            } label: {
                Label("Edit Story", systemImage: "pencil")
            }

            Button {
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .fontWeight(.bold)
                .foregroundStyle(Color.storyInk)
        }
        .accessibilityLabel("Story options")
    }

    private var entryIntroduction: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                VStack(spacing: 1) {
                    Text(entry.weekday)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.homeAccent)

                    Text(entry.day)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)
                }
                .frame(width: 48, height: 54)
                .background(Color.homeAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.homeAccent)

                    Text(entry.time)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.homeMutedText)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
                        isFavorite.toggle()
                    }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isFavorite ? Color.storyRose : Color.storyInk.opacity(0.58))
                        .frame(width: 38, height: 38)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }

            Text(entry.title)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)
                .fixedSize(horizontal: false, vertical: true)

            if let location = entry.location {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.storyInk.opacity(0.64))
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var photoStory: some View {
        Group {
            if let firstImageName = entry.imageNames.first {
                Button {
                    selectedImageName = firstImageName
                } label: {
                    Image(firstImageName)
                        .resizable()
                        .aspectRatio(momentImageAspectRatio(for: firstImageName), contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(.black.opacity(0.46), in: Circle())
                                .padding(10)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func momentImageAspectRatio(for imageName: String) -> CGFloat {
        guard let image = UIImage(named: imageName), image.size.height > 0 else {
            return 1
        }

        return image.size.width / image.size.height
    }

    private var journalPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("My story", systemImage: "text.quote")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.homeAccent)

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.storyGold)
            }

            Text(entry.body)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Color.storyInk.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Color.homeBorder)
                .frame(height: 1)

            Text(entry.reflection)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .italic()
                .lineSpacing(5)
                .foregroundStyle(Color.storyInk.opacity(0.67))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background {
            ZStack {
                Color.white

                VStack(spacing: 27) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.homeAccent.opacity(0.06))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 28)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var entryDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Story details")
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            HStack(spacing: 10) {
                DetailPill(systemName: "clock", text: entry.time, color: Color.homeAccent)

                if let location = entry.location {
                    DetailPill(systemName: "location", text: location, color: Color.homeAccent)
                }
            }
        }
    }

    private var referencePhotosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "paperclip")
                    .font(.system(size: 23, weight: .light))
                    .foregroundStyle(Color.storyInk.opacity(0.86))
                    .rotationEffect(.degrees(-18))
                    .frame(width: 24, height: 24)

                Text("Reference photos")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 7) {
                    ForEach(Array(visibleReferencePhotoNames.enumerated()), id: \.element) { index, imageName in
                        Button {
                            selectedImageName = imageName
                        } label: {
                            referencePhotoThumbnail(imageName: imageName)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open reference photo \(index + 1) of \(visibleReferencePhotoNames.count)")
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private func referencePhotoThumbnail(imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            }
    }

    private var visibleReferencePhotoNames: [String] {
        let count = min(max(entry.imageNames.count, 1), 5)
        return Array(referencePhotoNames.prefix(count))
    }

    private var referencePhotoNames: [String] {
        [
            "IMG_2214",
            "IMG_2382 2",
            "IMG_2385 2",
            "IMG_2390",
            "IMG_9080",
            "IMG_9102",
            "IMG_9113",
            "IMG_9114",
            "IMG_9126",
            "IMG_9127",
            "IMG_9131",
            "IMG_9140",
            "IMG_9144"
        ]
    }
}

private struct DetailPill: View {
    let systemName: String
    let text: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.storyInk.opacity(0.72))
            .lineLimit(1)
            .padding(.horizontal, 11)
            .frame(height: 34)
            .background(color.opacity(0.1), in: Capsule())
    }
}

private struct PhotoViewer: View {
    let imageName: String
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.storyInk
                    .ignoresSafeArea()

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 8)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(accentColor.opacity(0.9), in: Circle())
                    }
                }
            }
            .toolbarBackground(Color.storyInk, for: .navigationBar)
        }
    }
}

private struct VerticalComicViewer: View {
    let imageNames: [String]
    let initialIndex: Int
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss
    @State private var visibleIndex: Int

    init(imageNames: [String], initialIndex: Int, accentColor: Color) {
        self.imageNames = imageNames
        self.initialIndex = initialIndex
        self.accentColor = accentColor
        _visibleIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.storyInk
                .ignoresSafeArea()

            ZoomableVerticalComicView(
                imageNames: imageNames,
                initialIndex: initialIndex,
                visibleIndex: $visibleIndex
            )
            .background(Color.black)

            HStack {
                Text("\(visibleIndex + 1) of \(imageNames.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(.black.opacity(0.62), in: Capsule())

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(accentColor.opacity(0.94), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close comic viewer")
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
}

private struct ZoomableVerticalComicView: UIViewRepresentable {
    let imageNames: [String]
    let initialIndex: Int
    @Binding var visibleIndex: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        context.coordinator.stackView = stackView
        context.coordinator.pageViews = []
        context.coordinator.imageViews = imageNames.enumerated().compactMap { index, imageName in
            guard let image = UIImage(named: imageName) else {
                return nil
            }

            if index > 0 {
                stackView.addArrangedSubview(
                    makeImageBoundary(nextIndex: index, totalCount: imageNames.count)
                )
            }

            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .black
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false

            let pageView = UIView()
            pageView.backgroundColor = .black
            pageView.translatesAutoresizingMaskIntoConstraints = false
            pageView.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: pageView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor),
                pageView.heightAnchor.constraint(
                    equalTo: pageView.widthAnchor,
                    multiplier: image.size.height / image.size.width
                )
            ])

            stackView.addArrangedSubview(pageView)
            context.coordinator.pageViews.append(pageView)
            return imageView
        }

        DispatchQueue.main.async {
            context.coordinator.scrollToInitialImage(in: scrollView)
        }

        return scrollView
    }

    private func makeImageBoundary(nextIndex: Int, totalCount: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.035, alpha: 1)
        container.translatesAutoresizingMaskIntoConstraints = false

        let line = UIView()
        line.backgroundColor = UIColor.white.withAlphaComponent(0.86)
        line.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(line)

        let numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.text = "\(nextIndex + 1) / \(totalCount)"
        numberLabel.font = .systemFont(ofSize: 12, weight: .heavy)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.backgroundColor = UIColor(white: 0.035, alpha: 1)
        numberLabel.layer.cornerRadius = 12
        numberLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        numberLabel.layer.borderWidth = 1
        numberLabel.layer.masksToBounds = true
        container.addSubview(numberLabel)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 42),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 28),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -28),
            line.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            line.heightAnchor.constraint(equalToConstant: 1),
            numberLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            numberLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 56),
            numberLabel.heightAnchor.constraint(equalToConstant: 24)
        ])

        return container
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableVerticalComicView
        weak var stackView: UIStackView?
        var pageViews: [UIView] = []
        var imageViews: [UIImageView] = []
        private var didScrollToInitialImage = false

        init(parent: ZoomableVerticalComicView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            stackView
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            updateVisibleIndex(in: scrollView)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            updateVisibleIndex(in: scrollView)
        }

        func scrollToInitialImage(in scrollView: UIScrollView) {
            guard
                !didScrollToInitialImage,
                pageViews.indices.contains(parent.initialIndex)
            else {
                return
            }

            scrollView.layoutIfNeeded()
            stackView?.layoutIfNeeded()

            let imageView = pageViews[parent.initialIndex]
            let targetY = max(
                0,
                imageView.frame.midY - (scrollView.bounds.height / 2)
            )
            scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
            didScrollToInitialImage = true
            updateVisibleIndex(in: scrollView)
        }

        private func updateVisibleIndex(in scrollView: UIScrollView) {
            guard !pageViews.isEmpty else {
                return
            }

            let viewportCenterY = scrollView.contentOffset.y + (scrollView.bounds.height / 2)
            let zoomScale = scrollView.zoomScale
            let closestIndex = pageViews.indices.min { left, right in
                abs((pageViews[left].frame.midY * zoomScale) - viewportCenterY)
                    < abs((pageViews[right].frame.midY * zoomScale) - viewportCenterY)
            }

            guard
                let closestIndex,
                closestIndex != parent.visibleIndex
            else {
                return
            }

            parent.visibleIndex = closestIndex
        }
    }
}

private struct PrototypeEntryRow: View {
    let entry: PrototypeEntry
    let accentColor: Color
    var showsDate = true
    var thumbnailSize: CGFloat = 58
    var leadingCoverImageName: String?
    var showsReferencePhotos = true
    @State private var rowHeight: CGFloat = 0

    private var leadingCoverWidth: CGFloat {
        guard let leadingCoverImageName, rowHeight > 0 else {
            return 0
        }

        return rowHeight * coverAspectRatio(for: leadingCoverImageName)
    }

    var body: some View {
        rowContent
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: PrototypeEntryRowHeightPreferenceKey.self, value: proxy.size.height)
                }
            }
            .onPreferenceChange(PrototypeEntryRowHeightPreferenceKey.self) { height in
                rowHeight = height
            }
            .overlay(alignment: .leading) {
                if let leadingCoverImageName {
                    entryCoverPanel(imageName: leadingCoverImageName)
                }
            }
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 12) {
            if showsDate {
                VStack(spacing: 2) {
                    Text(entry.weekday)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.storyGray)

                    Text(entry.day)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)
                }
                .frame(width: 38)
                .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(1)

                Text(entry.body)
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(2)
                    .foregroundStyle(Color.storyInk.opacity(0.74))
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(entry.time)
                    if let location = entry.location {
                        Text("•")
                        Text(location)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accentColor)

                if showsReferencePhotos, !entry.imageNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 7) {
                            ForEach(Array(entry.imageNames.enumerated()), id: \.offset) { index, imageName in
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: thumbnailSize, height: thumbnailSize)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                                    }
                                    .accessibilityLabel("Story image \(index + 1) of \(entry.imageNames.count)")
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.storyGray.opacity(0.4))
                .padding(.top, 4)
        }
        .padding(.leading, leadingCoverImageName == nil ? 12 : leadingCoverWidth + 12)
        .padding(.trailing, 12)
        .padding(.vertical, 14)
    }

    private func entryCoverPanel(imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: leadingCoverWidth, height: rowHeight)
            .background(Color.homeCardGray)
            .accessibilityHidden(true)
    }

    private func coverAspectRatio(for imageName: String) -> CGFloat {
        guard
            let image = UIImage(named: imageName),
            image.size.height > 0
        else {
            return 0.74
        }

        return image.size.width / image.size.height
    }
}

private struct PrototypeEntryRowHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PrototypeChapter: Identifiable {
    enum Kind {
        case journal
        case storyboard
    }

    let id = UUID()
    let title: String
    let subtitle: String
    let color: Color
    let symbol: String
    let coverImageName: String?
    let kind: Kind
    let isFavorite: Bool
    var entries: [PrototypeEntry]

    var imageCount: Int {
        entries.reduce(0) { $0 + $1.imageNames.count }
    }

    var entryCountText: String {
        "\(entries.count) \(entries.count == 1 ? "story" : "stories")"
    }

    static let samples: [PrototypeChapter] = [
        PrototypeChapter(
            title: "Everyday Stories",
            subtitle: "Small moments worth remembering",
            color: Color(red: 0.34, green: 0.55, blue: 0.92),
            symbol: "sparkles",
            coverImageName: nil,
            kind: .journal,
            isFavorite: true,
            entries: [
                PrototypeEntry(
                    weekday: "TUE",
                    day: "16",
                    title: "A slow morning in Williamsburg",
                    body: "Coffee, a window seat, and nowhere I needed to be for an hour.",
                    time: "9:12 AM",
                    location: "Brooklyn, NY",
                    imageNames: ["storyboard1", "storyboard2"]
                ),
                PrototypeEntry(
                    weekday: "SUN",
                    day: "14",
                    title: "Sunday dinner",
                    body: "We stayed at the table long after dessert and retold the same family stories.",
                    time: "8:04 PM",
                    location: "Home",
                    imageNames: ["storyboard3", "storyboard4"]
                ),
                PrototypeEntry(
                    weekday: "FRI",
                    day: "05",
                    title: "The first warm night",
                    body: "Everyone seemed to have the same idea: walk slowly and stay outside.",
                    time: "10:18 PM",
                    location: nil,
                    imageNames: ["storyboard5"]
                )
            ]
        ),
        PrototypeChapter(
            title: "Summer Adventures",
            subtitle: "Trips, detours, and sunlit days",
            color: Color(red: 0.97, green: 0.62, blue: 0.28),
            symbol: "sun.max.fill",
            coverImageName: "storyboard6",
            kind: .storyboard,
            isFavorite: false,
            entries: [
                PrototypeEntry(
                    weekday: "SAT",
                    day: "06",
                    title: "The road to the coast",
                    body: "A playlist, an overpacked car, and four stops we never planned to make.",
                    time: "6:42 PM",
                    location: "Montauk, NY",
                    imageNames: ["storyboard6", "storyboard7"]
                ),
                PrototypeEntry(
                    weekday: "MON",
                    day: "01",
                    title: "Boardwalk at sunset",
                    body: "The sky turned peach just as the lights came on.",
                    time: "7:31 PM",
                    location: "Asbury Park, NJ",
                    imageNames: ["storyboard8", "storyboard9"]
                )
            ]
        ),
        PrototypeChapter(
            title: "Dream Log",
            subtitle: "Scenes from the edge of sleep",
            color: Color(red: 0.43, green: 0.38, blue: 0.78),
            symbol: "moon.stars.fill",
            coverImageName: nil,
            kind: .journal,
            isFavorite: true,
            entries: [
                PrototypeEntry(
                    weekday: "WED",
                    day: "27",
                    title: "The library under the ocean",
                    body: "Every book was sealed in glass, but I could still hear the pages turning.",
                    time: "6:18 AM",
                    location: nil,
                    imageNames: ["storyboard10", "storyboard11"]
                )
            ]
        ),
        PrototypeChapter(
            title: "People & Places",
            subtitle: "Portraits of a changing city",
            color: Color(red: 0.29, green: 0.70, blue: 0.65),
            symbol: "building.2.fill",
            coverImageName: nil,
            kind: .storyboard,
            isFavorite: false,
            entries: [
                PrototypeEntry(
                    weekday: "THU",
                    day: "21",
                    title: "Notes from the train",
                    body: "A collection of overheard sentences and passing neighborhoods.",
                    time: "5:26 PM",
                    location: "New York, NY",
                    imageNames: ["storyboard12", "storyboard13"]
                ),
                PrototypeEntry(
                    weekday: "TUE",
                    day: "12",
                    title: "The corner flower stand",
                    body: "He remembered everyone's favorite color.",
                    time: "11:03 AM",
                    location: "Chelsea",
                    imageNames: ["storyboard14", "storyboard15", "storyboard16"]
                )
            ]
        )
    ]
}

private enum UserChapterStore {
    private struct Record: Codable {
        let title: String
        let subtitle: String
        let symbol: String
        let kind: String
    }

    private static let storageKey = "StorytopiaUserChapters"

    static func load() -> [PrototypeChapter] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let records = try? JSONDecoder().decode([Record].self, from: data)
        else {
            return []
        }

        return records.map { record in
            PrototypeChapter(
                title: record.title,
                subtitle: record.subtitle,
                color: color(for: record.symbol),
                symbol: record.symbol,
                coverImageName: nil,
                kind: record.kind == "storyboard" ? .storyboard : .journal,
                isFavorite: false,
                entries: []
            )
        }
    }

    static func add(_ chapter: PrototypeChapter) {
        let existingRecords: [Record]
        if
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decodedRecords = try? JSONDecoder().decode([Record].self, from: data)
        {
            existingRecords = decodedRecords
        } else {
            existingRecords = []
        }

        let newRecord = Record(
            title: chapter.title,
            subtitle: chapter.subtitle,
            symbol: chapter.symbol,
            kind: chapter.kind == .storyboard ? "storyboard" : "journal"
        )

        guard let data = try? JSONEncoder().encode([newRecord] + existingRecords) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func delete(title: String) {
        let remainingRecords = records.filter { $0.title != title }
        guard let data = try? JSONEncoder().encode(remainingRecords) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static var records: [Record] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let records = try? JSONDecoder().decode([Record].self, from: data)
        else {
            return []
        }

        return records
    }

    private static func color(for symbol: String) -> Color {
        switch symbol {
        case "sun.max.fill":
            return Color(red: 0.97, green: 0.62, blue: 0.28)
        case "moon.stars.fill":
            return Color(red: 0.43, green: 0.38, blue: 0.78)
        case "building.2.fill":
            return Color(red: 0.29, green: 0.70, blue: 0.65)
        case "heart.fill":
            return Color.storyRose
        case "leaf.fill":
            return Color(red: 0.35, green: 0.64, blue: 0.43)
        default:
            return Color(red: 0.34, green: 0.55, blue: 0.92)
        }
    }
}

private enum DeletedSampleChapterStore {
    private static let storageKey = "StorytopiaDeletedSampleChapters"

    static func contains(title: String) -> Bool {
        titles.contains(title)
    }

    static func add(title: String) {
        var updatedTitles = titles
        updatedTitles.insert(title)
        UserDefaults.standard.set(Array(updatedTitles), forKey: storageKey)
    }

    private static var titles: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: storageKey) ?? [])
    }
}

private enum StoryEntryStore {
    private struct Record: Codable {
        let chapterTitle: String
        let weekday: String
        let day: String
        let title: String
        let body: String
        let time: String
        let location: String?
    }

    private static let storageKey = "StorytopiaChapterStories"

    static func load(for chapterTitle: String) -> [PrototypeEntry] {
        records
            .filter { $0.chapterTitle == chapterTitle }
            .map { record in
                PrototypeEntry(
                    weekday: record.weekday,
                    day: record.day,
                    title: record.title,
                    body: record.body,
                    time: record.time,
                    location: record.location,
                    imageNames: []
                )
            }
    }

    static func add(_ entry: PrototypeEntry, to chapterTitle: String) {
        let newRecord = Record(
            chapterTitle: chapterTitle,
            weekday: entry.weekday,
            day: entry.day,
            title: entry.title,
            body: entry.body,
            time: entry.time,
            location: entry.location
        )

        guard let data = try? JSONEncoder().encode([newRecord] + records) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func deleteAll(for chapterTitle: String) {
        let remainingRecords = records.filter { $0.chapterTitle != chapterTitle }
        guard let data = try? JSONEncoder().encode(remainingRecords) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static var records: [Record] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let records = try? JSONDecoder().decode([Record].self, from: data)
        else {
            return []
        }

        return records
    }
}

private struct PrototypeEntry: Identifiable {
    let id = UUID()
    let weekday: String
    let day: String
    let title: String
    let body: String
    let time: String
    let location: String?
    let imageNames: [String]

    func copy(imageNames: [String]) -> PrototypeEntry {
        PrototypeEntry(
            weekday: weekday,
            day: day,
            title: title,
            body: body,
            time: time,
            location: location,
            imageNames: imageNames
        )
    }

    var reflection: String {
        switch title {
        case "A slow morning in Williamsburg":
            return "I want to remember how spacious the day felt before it filled up."
        case "Sunday dinner":
            return "Some traditions survive because nobody is ready for the conversation to end."
        case "The first warm night":
            return "The whole neighborhood felt like it had been waiting at the same window."
        case "The road to the coast":
            return "The detours became the parts of the trip we quoted on the way home."
        case "Boardwalk at sunset":
            return "For a few minutes, the sky and the old neon signs seemed to agree on a color."
        case "The library under the ocean":
            return "I woke up wondering who kept reading after I left."
        case "Notes from the train":
            return "A city tells on itself in the half-sentences people leave behind."
        case "The corner flower stand":
            return "Being remembered in a small way can change the shape of an ordinary morning."
        default:
            return "A small moment, kept here before it could slip away."
        }
    }
}

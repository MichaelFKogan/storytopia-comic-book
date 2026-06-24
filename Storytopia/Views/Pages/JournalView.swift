import Foundation
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
    @State private var editMode: EditMode = .inactive
    @State private var journalBeingRenamed: PrototypeChapter?
    @State private var renamedJournalTitle = ""

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

                VStack(alignment: .leading, spacing: 10) {
                    header
                        .padding(.horizontal, 16)

                    if showsPrototypeData {
                        prototypeNotice
                            .padding(.horizontal, 16)
                    }

                    chapterList
                }

                BottomNavigationBar(selectedPage: $selectedPage)

            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.editMode, $editMode)
        }
        .onAppear {
            savedDrafts = CreateEntryDraftStore.loadAll()
            chapters = DailyJournalData.allChapters()
            isDraftSaved = !savedDrafts.isEmpty
        }
        .preferredColorScheme(.light)
        .alert("Rename Journal", isPresented: isRenameAlertPresented) {
            TextField("Journal name", text: $renamedJournalTitle)

            Button("Cancel", role: .cancel) {
                journalBeingRenamed = nil
                renamedJournalTitle = ""
            }

            Button("Save") {
                renameSelectedJournal()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Text("Journals")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

            EditButton()
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.homeAccent)

            Button {
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.storyInk, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create a new journal")
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
        List {
            if showsPrototypeData {
                Section {
                    if chapters.isEmpty {
                        noSearchResults
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                    } else {
                        journalRows
                    }
                } header: {
                    HStack(alignment: .lastTextBaseline) {
                        Text("Your Journals")
                            .font(.system(size: 19, weight: .bold, design: .serif))
                            .foregroundStyle(Color.storyInk)
                            .textCase(nil)

                        Spacer()

                        Text("\(chapters.count) \(chapters.count == 1 ? "journal" : "journals")")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.homeMutedText)
                            .textCase(nil)
                    }
                }
            } else {
                Section {
                    emptyState
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.homePageBackground)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 76)
        }
    }

    private var journalRows: some View {
        ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
            NavigationLink {
                dailyJournalDetail(for: chapter, dayOffset: index)
            } label: {
                JournalChapterListRow(chapter: chapter)
            }
            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 12))
            .listRowBackground(Color.homePageBackground)
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    beginRenaming(chapter)
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                .tint(Color.homeAccent)
            }
        }
        .onDelete(perform: deleteChapters)
        .onMove(perform: moveChapters)
    }

    private var isRenameAlertPresented: Binding<Bool> {
        Binding(
            get: { journalBeingRenamed != nil },
            set: { isPresented in
                if !isPresented {
                    journalBeingRenamed = nil
                    renamedJournalTitle = ""
                }
            }
        )
    }

    private func beginRenaming(_ chapter: PrototypeChapter) {
        journalBeingRenamed = chapter
        renamedJournalTitle = chapter.title
    }

    private func renameSelectedJournal() {
        guard
            let selectedJournal = journalBeingRenamed,
            let index = chapters.firstIndex(where: { $0.id == selectedJournal.id })
        else {
            return
        }

        let trimmedTitle = renamedJournalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        let oldTitle = chapters[index].title
        chapters[index] = chapters[index].copy(title: trimmedTitle)
        UserChapterStore.rename(title: oldTitle, to: trimmedTitle)
        StoryEntryStore.renameChapter(from: oldTitle, to: trimmedTitle)
        journalBeingRenamed = nil
        renamedJournalTitle = ""
    }

    private func deleteChapters(at offsets: IndexSet) {
        offsets
            .map { chapters[$0] }
            .forEach { chapter in
                let isUserJournal = UserChapterStore.contains(title: chapter.title)
                UserChapterStore.delete(title: chapter.title)
                if !isUserJournal {
                    DeletedSampleChapterStore.add(title: chapter.title)
                }
                StoryEntryStore.deleteAll(for: chapter.title)
            }

        chapters.remove(atOffsets: offsets)
    }

    private func moveChapters(from source: IndexSet, to destination: Int) {
        chapters.move(fromOffsets: source, toOffset: destination)
        UserChapterStore.replace(with: chapters.filter { UserChapterStore.contains(title: $0.title) })
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
    @State private var selectedTab: DaybookTab = .entries
    @State private var comicPageIndex = 0
    @State private var isComicPagePresented = false
    @State private var isShowingNewEntry = false
    @State private var selectedGalleryImageIndex: Int?

    private var comicBook: DaybookComicBook {
        DaybookComicBook(chapters: chapters)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.white
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        pageHeader
                        tabSwitcher

                        selectedTabContent
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 92)
                }

                BottomNavigationBar(selectedPage: $selectedPage)
            }
            .navigationDestination(isPresented: $isComicPagePresented) {
                DaybookComicStandalonePage(
                    comicBook: comicBook,
                    currentPageIndex: $comicPageIndex
                )
            }
            .navigationDestination(isPresented: $isShowingNewEntry) {
                NewStorySheet(
                    chapterTitle: todayJournalTitle,
                    accentColor: Color.homeAccent,
                    initialDate: DailyJournalData.journalDate(dayOffset: 0),
                    collectionLabel: "Daily Journal",
                    locksEntryDate: true
                ) { entry in
                    addEntryToToday(entry)
                    selectedTab = .entries
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            chapters = DailyJournalData.allChapters()
            comicPageIndex = clampedComicPageIndex(comicPageIndex)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { selectedGalleryImageIndex != nil },
                set: { isPresented in
                    if !isPresented {
                        selectedGalleryImageIndex = nil
                    }
                }
            )
        ) {
            if let selectedGalleryImageIndex {
                VerticalComicViewer(
                    imageNames: comicBook.storyPages.map(\.imageName),
                    initialIndex: selectedGalleryImageIndex,
                    accentColor: Color.homeAccent
                )
            }
        }
    }

    private var pageHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            Text("June 2026")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Button {
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color.storyInk)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose month")

            Button {
                isShowingNewEntry = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.storyInk, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create a new journal entry")
        }
        .padding(.horizontal, 22)
        .padding(.top, 2)
    }

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(DaybookTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(selectedTab == tab ? Color.homeAccent : Color.homeMutedText.opacity(0.78))

                        Capsule()
                            .fill(selectedTab == tab ? Color.homeAccent : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.top, 2)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .entries:
            AllJournalEntriesSection(chapters: $chapters)
        case .gallery:
            DaybookGalleryGrid(comicBook: comicBook) { imageIndex in
                selectedGalleryImageIndex = imageIndex
            }
            .padding(.horizontal, 16)
        case .comic:
            DaybookComicTab(comicBook: comicBook, currentPageIndex: $comicPageIndex)
                .padding(.horizontal, 16)
        }
    }

    private func openComic(at pageIndex: Int) {
        comicPageIndex = clampedComicPageIndex(pageIndex)
        isComicPagePresented = true
    }

    private func clampedComicPageIndex(_ pageIndex: Int) -> Int {
        min(max(0, pageIndex), max(0, comicBook.totalPageCount - 1))
    }

    private var todayJournalTitle: String {
        guard let chapter = chapters.first else {
            return "Today"
        }

        return DailyJournalData.dateTitledChapter(from: chapter, dayOffset: 0).title
    }

    private func addEntryToToday(_ entry: PrototypeEntry) {
        guard let chapter = chapters.first else {
            return
        }

        chapters[0].entries.insert(entry, at: 0)
        StoryEntryStore.add(entry, to: chapter.title)
    }
}

private struct DaybookComicStandalonePage: View {
    let comicBook: DaybookComicBook
    @Binding var currentPageIndex: Int

    var body: some View {
        ZStack {
            Color.homePageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    DaybookComicTab(
                        comicBook: comicBook,
                        currentPageIndex: $currentPageIndex,
                        bookHorizontalInset: 2,
                        headerHorizontalInset: 16,
                        availableBookWidth: UIScreen.main.bounds.width - 4
                    )
                }
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Comic")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear {
            currentPageIndex = min(max(0, currentPageIndex), max(0, comicBook.totalPageCount - 1))
        }
    }
}

private enum DaybookTab: String, CaseIterable, Identifiable {
    case entries
    case gallery
    case comic

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .entries:
            return "Entries"
        case .gallery:
            return "Gallery"
        case .comic:
            return "Comic"
        }
    }
}

private struct DaybookGalleryGrid: View {
    let comicBook: DaybookComicBook
    let onOpenImage: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text("Storyboards")
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Text(comicBook.storyboardCountText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)
            }
            .padding(.top, 6)

            if comicBook.storyPages.isEmpty {
                DaybookEmptyComicState(title: "No storyboards yet", message: "Storyboards from this month will appear here.")
            } else {
                GeometryReader { proxy in
                    let spacing: CGFloat = 8
                    let columnWidth = (proxy.size.width - spacing) / 2

                    HStack(alignment: .top, spacing: spacing) {
                        storyboardColumn(
                            pages: comicBook.storyPages.enumerated().filter { $0.offset.isMultiple(of: 2) },
                            width: columnWidth
                        )

                        storyboardColumn(
                            pages: comicBook.storyPages.enumerated().filter { !$0.offset.isMultiple(of: 2) },
                            width: columnWidth
                        )
                    }
                }
                .frame(height: masonryHeight(for: comicBook.storyPages))
            }
        }
    }

    private func storyboardColumn(
        pages: [(offset: Int, element: DaybookStoryPage)],
        width: CGFloat
    ) -> some View {
        VStack(spacing: 8) {
            ForEach(pages, id: \.element.id) { item in
                let page = item.element
                Button {
                    onOpenImage(item.offset)
                } label: {
                    Image(page.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: galleryHeight(for: page, width: width))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            Text("\(item.offset + 1)")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .frame(height: 24)
                                .background(.black.opacity(0.62), in: Capsule())
                                .padding(8)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(page.title), image \(item.offset + 1) of \(comicBook.storyPages.count)")
            }
        }
    }

    private func galleryHeight(for page: DaybookStoryPage, width: CGFloat) -> CGFloat {
        guard let image = UIImage(named: page.imageName), image.size.width > 0 else {
            return width * 1.28
        }

        return min(width * 1.72, max(width * 0.88, width * (image.size.height / image.size.width)))
    }

    private func masonryHeight(for pages: [DaybookStoryPage]) -> CGFloat {
        let rows = max(1, Int(ceil(Double(pages.count) / 2.0)))
        return CGFloat(rows) * 312 + CGFloat(max(0, rows - 1)) * 8
    }
}

private struct DaybookComicTab: View {
    let comicBook: DaybookComicBook
    @Binding var currentPageIndex: Int
    var bookHorizontalInset: CGFloat = 0
    var headerHorizontalInset: CGFloat = 0
    var availableBookWidth: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text(comicBook.monthTitle)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Text(comicBook.pageCountText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)
            }
            .padding(.top, 6)
            .padding(.horizontal, headerHorizontalInset)

            if comicBook.storyPages.isEmpty {
                DaybookEmptyComicState(title: "No comic pages yet", message: "Entries with storyboards will become this month's issue.")
                    .padding(.horizontal, headerHorizontalInset)
            } else {
                DaybookComicBookView(
                    comicBook: comicBook,
                    currentPageIndex: $currentPageIndex,
                    availableWidth: availableBookWidth
                )
                .padding(.horizontal, bookHorizontalInset)
            }
        }
    }
}

private struct DaybookComicBookView: View {
    let comicBook: DaybookComicBook
    @Binding var currentPageIndex: Int
    var showsCaption = true
    var availableWidth: CGFloat?
    var showsCoverOverlay = false
    var onOpenComic: (() -> Void)?
    @State private var programmaticTurnOffset = 0
    @State private var programmaticTurnProgress: CGFloat = 0
    private let binderWidth: CGFloat = 12

    init(
        comicBook: DaybookComicBook,
        currentPageIndex: Binding<Int>,
        showsCaption: Bool = true,
        availableWidth: CGFloat? = nil,
        showsCoverOverlay: Bool = false,
        onOpenComic: (() -> Void)? = nil
    ) {
        self.comicBook = comicBook
        self._currentPageIndex = currentPageIndex
        self.showsCaption = showsCaption
        self.availableWidth = availableWidth
        self.showsCoverOverlay = showsCoverOverlay
        self.onOpenComic = onOpenComic
    }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let layoutWidth = max(1, availableWidth ?? proxy.size.width)
                let maxPageWidth = max(1, layoutWidth - binderWidth)
                let imageAspectRatio = comicBook.imageAspectRatio(for: currentPageIndex)
                let maxBookHeight = proxy.size.height
                let pageHeight = min(maxPageWidth / imageAspectRatio, maxBookHeight)
                let pageWidth = pageHeight * imageAspectRatio
                let bookWidth = pageWidth + binderWidth

                HStack(spacing: 0) {
                    DaybookComicBinder()
                        .frame(width: binderWidth, height: pageHeight)

                    DaybookPageTurnView(
                        comicBook: comicBook,
                        currentPageIndex: $currentPageIndex,
                        programmaticTurnOffset: programmaticTurnOffset,
                        programmaticTurnProgress: programmaticTurnProgress,
                        showsCoverOverlay: showsCoverOverlay
                    )
                    .frame(width: pageWidth, height: pageHeight)
                }
                .frame(width: bookWidth, height: pageHeight)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 0.03, green: 0.03, blue: 0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.24), radius: 18, y: 10)
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(height: bookHeight)

            HStack(spacing: 10) {
                Button {
                    turnPage(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(currentPageIndex == 0 || isTurningProgrammatically ? Color.homeMutedText.opacity(0.35) : Color.storyInk)
                        .frame(width: 38, height: 34)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(currentPageIndex == 0 || isTurningProgrammatically)
                .accessibilityLabel("Previous comic page")

                Text("\(currentPageIndex + 1) / \(comicBook.totalPageCount)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.homeMutedText)
                    .frame(minWidth: 58)

                Button {
                    turnPage(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(currentPageIndex >= comicBook.totalPageCount - 1 || isTurningProgrammatically ? Color.homeMutedText.opacity(0.35) : Color.storyInk)
                        .frame(width: 38, height: 34)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(currentPageIndex >= comicBook.totalPageCount - 1 || isTurningProgrammatically)
                .accessibilityLabel("Next comic page")
            }

            if let onOpenComic {
                Button(action: onOpenComic) {
                    Label("Open Comic", systemImage: "book.pages.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(Color.storyInk, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Comic Reader")
            }

            if showsCaption {
                DaybookComicPageCaption(comicBook: comicBook, pageIndex: currentPageIndex)
            }
        }
        .onAppear {
            currentPageIndex = clampedPageIndex(currentPageIndex)
        }
        .onChange(of: comicBook.totalPageCount) { _ in
            currentPageIndex = clampedPageIndex(currentPageIndex)
        }
    }

    private func turnPage(by offset: Int) {
        guard !isTurningProgrammatically else {
            return
        }

        let nextPageIndex = clampedPageIndex(currentPageIndex + offset)
        guard nextPageIndex != currentPageIndex else {
            return
        }

        programmaticTurnOffset = offset
        programmaticTurnProgress = 0.02

        withAnimation(.easeInOut(duration: 0.32)) {
            programmaticTurnProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            var transaction = Transaction()
            transaction.animation = nil

            withTransaction(transaction) {
                currentPageIndex = nextPageIndex
                programmaticTurnOffset = 0
                programmaticTurnProgress = 0
            }
        }
    }

    private func clampedPageIndex(_ pageIndex: Int) -> Int {
        min(max(0, pageIndex), max(0, comicBook.totalPageCount - 1))
    }

    private var bookHeight: CGFloat {
        let layoutWidth = max(1, availableWidth ?? UIScreen.main.bounds.width - 32)
        let maxPageWidth = max(1, layoutWidth - binderWidth)
        return maxPageWidth / comicBook.imageAspectRatio(for: currentPageIndex)
    }

    private var isTurningProgrammatically: Bool {
        programmaticTurnOffset != 0
    }
}

private struct DaybookComicBinder: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.08),
                    Color(red: 0.16, green: 0.16, blue: 0.18),
                    Color(red: 0.04, green: 0.04, blue: 0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Rectangle()
                .fill(.black.opacity(0.38))
                .frame(width: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DaybookPageTurnView: View {
    let comicBook: DaybookComicBook
    @Binding var currentPageIndex: Int
    let programmaticTurnOffset: Int
    let programmaticTurnProgress: CGFloat
    let showsCoverOverlay: Bool
    @GestureState private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let pageTurn = pageTurnState(width: width)

            ZStack {
                pageView(at: currentPageIndex)

                if pageTurn.isTurningForward, currentPageIndex < comicBook.totalPageCount - 1 {
                    pageView(at: currentPageIndex + 1)

                    pageView(at: currentPageIndex)
                        .pageFoldOverlay(progress: pageTurn.progress, isForward: true)
                        .rotation3DEffect(
                            .degrees(-148 * pageTurn.progress),
                            axis: (x: 0, y: 1, z: 0),
                            anchor: .leading,
                            perspective: 0.72
                        )
                        .scaleEffect(x: 1 - 0.08 * pageTurn.progress, y: 1, anchor: .leading)
                        .shadow(color: .black.opacity(0.36 * pageTurn.progress), radius: 18, x: -16, y: 4)
                } else if pageTurn.isTurningBackward, currentPageIndex > 0 {
                    pageView(at: currentPageIndex)
                        .pageRevealedUnderFold(progress: pageTurn.progress)

                    pageView(at: currentPageIndex - 1)
                        .pageFoldOverlay(progress: pageTurn.progress, isForward: false)
                        .rotation3DEffect(
                            .degrees(-148 + 148 * pageTurn.progress),
                            axis: (x: 0, y: 1, z: 0),
                            anchor: .leading,
                            perspective: 0.72
                        )
                        .scaleEffect(x: 0.92 + 0.08 * pageTurn.progress, y: 1, anchor: .leading)
                        .shadow(color: .black.opacity(0.36 * pageTurn.progress), radius: 18, x: -16, y: 4)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .updating($dragTranslation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        finishPageTurn(value, width: width)
                    }
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Comic book page \(currentPageIndex + 1) of \(comicBook.totalPageCount)")
        }
    }

    @ViewBuilder
    private func pageView(at pageIndex: Int) -> some View {
        if pageIndex == 0 {
            DaybookComicCoverPage(
                comicBook: comicBook,
                showsCoverOverlay: showsCoverOverlay
            )
        } else if pageIndex == comicBook.totalPageCount - 1 {
            DaybookComicBackCoverPage(comicBook: comicBook)
        } else {
            let storyPage = comicBook.storyPages[pageIndex - 1]

            DaybookComicStoryPage(page: storyPage)
        }
    }

    private func pageTurnState(width: CGFloat) -> (progress: CGFloat, isTurningForward: Bool, isTurningBackward: Bool) {
        if programmaticTurnOffset != 0 {
            return (
                min(1, max(0.02, programmaticTurnProgress)),
                programmaticTurnOffset > 0,
                programmaticTurnOffset < 0
            )
        }

        let progress = min(1, abs(dragTranslation) / (width * 0.62))
        return (
            max(0.02, progress),
            dragTranslation < -4,
            dragTranslation > 4
        )
    }

    private func finishPageTurn(_ value: DragGesture.Value, width: CGFloat) {
        let predicted = value.predictedEndTranslation.width
        let threshold = max(64, width * 0.22)

        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            if predicted < -threshold, currentPageIndex < comicBook.totalPageCount - 1 {
                currentPageIndex += 1
            } else if predicted > threshold, currentPageIndex > 0 {
                currentPageIndex -= 1
            }
        }
    }
}

private extension View {
    func pageFoldOverlay(progress: CGFloat, isForward: Bool) -> some View {
        modifier(DaybookPageFoldOverlay(progress: progress, isForward: isForward))
    }

    func pageRevealedUnderFold(progress: CGFloat) -> some View {
        modifier(DaybookPageRevealOverlay(progress: progress))
    }
}

private struct DaybookPageFoldOverlay: ViewModifier {
    let progress: CGFloat
    let isForward: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .leading) {
                LinearGradient(
                    colors: [
                        .black.opacity(0.34 * progress),
                        .clear,
                        .white.opacity(0.18 * progress),
                        .black.opacity(0.28 * progress)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .overlay(alignment: isForward ? .trailing : .leading) {
                Rectangle()
                    .fill(.white.opacity(0.42 * progress))
                    .frame(width: 2)
                    .blur(radius: 0.7)
                    .padding(.vertical, 8)
            }
            .overlay(alignment: isForward ? .trailing : .leading) {
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.34 * progress)
                    ],
                    startPoint: isForward ? .leading : .trailing,
                    endPoint: isForward ? .trailing : .leading
                )
                .frame(width: 54)
            }
    }
}

private struct DaybookPageRevealOverlay: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .black.opacity(0.2 * progress),
                        .clear,
                        .white.opacity(0.08 * progress)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

private struct DaybookComicPageCaption: View {
    let comicBook: DaybookComicBook
    let pageIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.homeMutedText)

            Text(title)
                .font(.system(size: 24, weight: .black, design: .serif))
                .foregroundStyle(Color.storyInk)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let bodyText {
                Text(bodyText)
                    .font(.system(size: 14, weight: .semibold))
                    .lineSpacing(4)
                    .foregroundStyle(Color.storyInk.opacity(0.72))
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var eyebrow: String {
        if pageIndex == 0 {
            return "Issue #\(comicBook.issueNumber) • 1 / \(comicBook.totalPageCount)"
        }

        if pageIndex == comicBook.totalPageCount - 1 {
            return "Back Cover • \(pageIndex + 1) / \(comicBook.totalPageCount)"
        }

        return "\(storyPage.dateText) • \(pageIndex + 1) / \(comicBook.totalPageCount)"
    }

    private var title: String {
        if pageIndex == 0 {
            return comicBook.monthTitle
        }

        if pageIndex == comicBook.totalPageCount - 1 {
            return "Issue Notes"
        }

        return storyPage.title
    }

    private var bodyText: String? {
        if pageIndex == 0 {
            return "\(comicBook.entryCountText) • \(comicBook.storyboardCountText)"
        }

        if pageIndex == comicBook.totalPageCount - 1 {
            return "Most visited: \(comicBook.mostVisitedLocation)\nTheme: \(comicBook.mostCommonTheme)"
        }

        return storyPage.excerpt
    }

    private var storyPage: DaybookStoryPage {
        comicBook.storyPages[min(max(0, pageIndex - 1), max(0, comicBook.storyPages.count - 1))]
    }
}

private struct DaybookEmptyComicState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.pages")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.homeAccent.opacity(0.68))

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Text(message)
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
}

private struct DaybookComicCoverPage: View {
    let comicBook: DaybookComicBook
    var showsCoverOverlay = false

    var body: some View {
        GeometryReader { proxy in
            Image(comicBook.coverImageName)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay(alignment: .leading) {
                    LinearGradient(
                        colors: [.black.opacity(0.34), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 22)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.black, lineWidth: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .overlay {
                    if showsCoverOverlay {
                        Color.black.opacity(0.28)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if showsCoverOverlay {
                        coverText
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                }
                .shadow(color: .black.opacity(0.32), radius: 12, y: 7)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }

    private var coverText: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Label(comicBook.entryCountText.lowercased(), systemImage: "book.pages.fill")
                Label(comicBook.storyboardCountText.lowercased(), systemImage: "photo.on.rectangle.angled")
            }
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.82))
            .lineLimit(1)
            .minimumScaleFactor(0.68)

            Text(comicBook.monthTitle)
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text("Daily")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)
        }
        .shadow(color: .black.opacity(0.58), radius: 8, y: 3)
    }
}

private struct DaybookComicStoryPage: View {
    let page: DaybookStoryPage

    var body: some View {
        GeometryReader { proxy in
            Image(page.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay(alignment: .leading) {
                    LinearGradient(
                        colors: [.black.opacity(0.16), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.black, lineWidth: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }
}

private struct DaybookComicBackCoverPage: View {
    let comicBook: DaybookComicBook

    var body: some View {
        GeometryReader { proxy in
            Image(comicBook.backCoverImageName)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay(alignment: .leading) {
                    LinearGradient(
                        colors: [.black.opacity(0.34), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 22)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.black, lineWidth: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.32), radius: 12, y: 7)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }
}

private struct DaybookComicBook {
    let chapters: [PrototypeChapter]

    private let storyboardImageNames = (1...16).map { "storyboard\($0)" }
    let issueNumber = 23
    let monthTitle = "June 2026"

    var storyPages: [DaybookStoryPage] {
        Array(monthEntries.prefix(storyboardImageNames.count).enumerated()).map { index, item in
            DaybookStoryPage(
                entry: item.entry,
                date: item.date,
                chapterTitle: item.chapter.title,
                imageName: storyboardImageNames[index]
            )
        }
    }

    var totalPageCount: Int {
        storyPages.count + 2
    }

    var coverImageName: String {
        storyPages.first?.imageName ?? "storyboard1"
    }

    var backCoverImageName: String {
        storyPages.last?.imageName ?? coverImageName
    }

    func imageAspectRatio(for pageIndex: Int) -> CGFloat {
        let imageName: String

        if pageIndex == 0 {
            imageName = coverImageName
        } else if pageIndex == totalPageCount - 1 {
            imageName = backCoverImageName
        } else {
            imageName = storyPages[min(max(0, pageIndex - 1), max(0, storyPages.count - 1))].imageName
        }

        guard let image = UIImage(named: imageName), image.size.height > 0 else {
            return 0.57
        }

        return image.size.width / image.size.height
    }

    var entryCountValue: String {
        "\(monthEntries.count)"
    }

    var storyboardCountValue: String {
        "\(storyPages.count)"
    }

    var entryCountText: String {
        "\(entryCountValue) \(monthEntries.count == 1 ? "Entry" : "Entries")"
    }

    var storyboardCountText: String {
        "\(storyboardCountValue) \(storyPages.count == 1 ? "Storyboard" : "Storyboards")"
    }

    var pageCountText: String {
        "\(totalPageCount) \(totalPageCount == 1 ? "page" : "pages")"
    }

    var mostVisitedLocation: String {
        mostCommonValue(storyPages.compactMap(\.location)) ?? "Uncharted"
    }

    var mostCommonTheme: String {
        mostCommonValue(storyPages.map(\.chapterTitle)) ?? "Everyday Stories"
    }

    var topCharactersText: String {
        let names = storyPages
            .flatMap { page in
                characterWords(in: page.title + " " + page.excerpt)
            }
            .filter { word in
                guard let firstScalar = word.unicodeScalars.first else { return false }
                return CharacterSet.uppercaseLetters.contains(firstScalar)
                    && word.count > 2
                    && !excludedCharacterWords.contains(word)
            }

        let topNames = Array(countsByValue(names).sorted { $0.value > $1.value }.prefix(2).map(\.key))
        return topNames.isEmpty ? "Mike\nCooper" : topNames.joined(separator: "\n")
    }

    private var monthEntries: [DaybookMonthEntry] {
        chapters.enumerated()
            .flatMap { dayOffset, chapter in
                let date = DailyJournalData.journalDate(dayOffset: dayOffset)
                return chapter.entries.enumerated().map { entryIndex, entry in
                    DaybookMonthEntry(
                        date: date,
                        entryIndex: entryIndex,
                        chapter: chapter,
                        entry: entry
                    )
                }
            }
            .sorted { left, right in
                if left.date == right.date {
                    return left.entryIndex < right.entryIndex
                }

                return left.date < right.date
            }
    }

    private var excludedCharacterWords: Set<String> {
        ["The", "Every", "June", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    }

    private func mostCommonValue(_ values: [String]) -> String? {
        countsByValue(values).max { $0.value < $1.value }?.key
    }

    private func countsByValue(_ values: [String]) -> [String: Int] {
        values.reduce(into: [:]) { counts, value in
            let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanedValue.isEmpty else {
                return
            }

            counts[cleanedValue, default: 0] += 1
        }
    }

    private func characterWords(in text: String) -> [String] {
        text.components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }
}

private struct DaybookMonthEntry {
    let date: Date
    let entryIndex: Int
    let chapter: PrototypeChapter
    let entry: PrototypeEntry
}

private struct DaybookStoryPage: Identifiable {
    let entry: PrototypeEntry
    let date: Date
    let chapterTitle: String
    let imageName: String

    var id: String {
        imageName
    }

    var title: String {
        entry.title
    }

    var excerpt: String {
        entry.body
    }

    var location: String? {
        entry.location
    }

    var dateText: String {
        date.formatted(.dateTime.month(.wide).day())
    }
}

enum DailyJournalData {
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
        let datedChapter = dateTitledChapter(from: chapter, dayOffset: dayOffset)

        return PrototypeChapterDetailView(
            chapter: datedChapter.copy(title: chapter.title),
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

private let regularSetImageNames: [String] = [
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

private struct AllJournalEntriesSection: View {
    @Binding var chapters: [PrototypeChapter]

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            if allJournalEntries.isEmpty {
                noJournalEntries
                    .padding(.horizontal, 16)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(allJournalEntryDays) { day in
                        journalDayGroup(day)
                    }
                }
            }
        }
    }

    private func journalDayGroup(_ day: DailyJournalDaySummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                dailyJournalDetail(for: day.sourceChapter, dayOffset: day.dayOffset)
            } label: {
                journalDayHeader(day)
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
                        thumbnailSize: 58,
                        inlineLeadingCoverImageName: item.coverImageName,
                        showsReferencePhotos: false,
                        isCompact: true,
                        showsBodyPreview: true
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.homeBorder.opacity(0.7))
                        .frame(height: 0.5)
                }
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
        HStack(alignment: .center, spacing: 8) {
            Text(day.compactSectionDateText)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Color.homeMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.86)

            Spacer(minLength: 8)

            Text("\(day.entries.count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.homeMutedText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .padding(.horizontal, 16)
        .background(Color.homePageBackground)
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

    var sectionDateText: String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var compactSectionDateText: String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased()
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

private struct JournalChapterListRow: View {
    let chapter: PrototypeChapter

    var body: some View {
        HStack(spacing: 10) {
            JournalListCover(
                color: chapter.color,
                imageName: nil,
                width: 34,
                height: 44
            )
            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text("\(chapter.entries.count) \(chapter.entries.count == 1 ? "entry" : "entries")")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.homeMutedText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .frame(minHeight: 54)
        .accessibilityLabel(chapter.title)
    }
}

private struct JournalListCover: View {
    let color: Color
    let imageName: String?
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 3,
                bottomLeadingRadius: 3,
                bottomTrailingRadius: 5,
                topTrailingRadius: 5,
                style: .continuous
            )
            .fill(color)

            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.12))
                    .clipped()
            }

            HStack {
                Rectangle()
                    .fill(Color.black.opacity(0.22))
                    .frame(width: 6)

                Spacer()

                Rectangle()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 2)
            }

            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.34))
                    .frame(width: 1)
                    .padding(.leading, 4)

                Spacer()
            }
        }
        .frame(width: width, height: height)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 3,
                bottomLeadingRadius: 3,
                bottomTrailingRadius: 5,
                topTrailingRadius: 5,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 3,
                bottomLeadingRadius: 3,
                bottomTrailingRadius: 5,
                topTrailingRadius: 5,
                style: .continuous
            )
            .stroke(Color.black.opacity(0.16), lineWidth: 0.8)
        )
        .shadow(color: color.opacity(0.20), radius: 4, y: 2)
    }
}

private struct NotebookCover: View {
    let color: Color
    let symbol: String?
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

            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }

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
                color: chapter.color,
                symbol: nil,
                imageName: nil,
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

                if presentation != .dailyJournal {
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
                LazyVStack(spacing: 14) {
                    ForEach(Array(chapter.entries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            PrototypeEntryDetailView(
                                entry: entry,
                                chapter: chapter,
                                title: presentation == .dailyJournal ? "Journal Entry" : "Story"
                            )
                        } label: {
                            PrototypeEntryRow(
                                entry: detailDisplayEntry(for: entry, entryIndex: index),
                                accentColor: Color.homeAccent,
                                thumbnailSize: detailEntryThumbnailSize
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
            }
        }
        .background {
            if chapter.entries.isEmpty {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
            }
        }
        .overlay {
            if chapter.entries.isEmpty {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.homeBorder, lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(chapter.entries.isEmpty ? 0.06 : 0), radius: 12, y: 4)
    }

    private var detailEntryThumbnailSize: CGFloat {
        presentation == .dailyJournal ? 50 : 58
    }

    private func detailDisplayEntry(for entry: PrototypeEntry, entryIndex: Int) -> PrototypeEntry {
        guard presentation == .dailyJournal, !entry.imageNames.isEmpty else {
            return entry
        }

        return entry.copy(
            imageNames: regularPhotoNames(
                startIndex: entryIndex * 2,
                count: entry.imageNames.count
            )
        )
    }

    private func regularPhotoNames(startIndex: Int, count: Int) -> [String] {
        (0..<count).map { offset in
            regularSetImageNames[(startIndex + offset) % regularSetImageNames.count]
        }
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
    var inlineLeadingCoverImageName: String?
    var trailingCoverImageName: String?
    var showsReferencePhotos = true
    var isCompact = false
    var showsBodyPreview = true
    @State private var rowHeight: CGFloat = 0
    @State private var rowContentHeight: CGFloat = 0

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
        HStack(alignment: .center, spacing: 12) {
            if showsDate {
                VStack(spacing: 2) {
                    Text(entry.weekday)
                        .font(.system(size: isCompact ? 8 : 9, weight: .bold))
                        .foregroundStyle(Color.storyGray)

                    Text(entry.day)
                        .font(.system(size: isCompact ? 17 : 20, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)
                }
                .frame(width: isCompact ? 30 : 38)
                .padding(.top, 2)
            }

            if let inlineLeadingCoverImageName {
                inlineCoverPanel(imageName: inlineLeadingCoverImageName)
            }

            VStack(alignment: .leading, spacing: isCompact ? 3 : 5) {
                Text(entry.title)
                    .font(.system(size: isCompact ? 15 : 16, weight: .bold))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(isCompact ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)

                if showsBodyPreview {
                    Text(entry.body)
                        .font(.system(size: isCompact ? 13 : 13, weight: .medium))
                        .lineSpacing(isCompact ? 1 : 2)
                        .foregroundStyle(Color.storyInk.opacity(0.74))
                        .lineLimit(isCompact ? 1 : 2)
                }

                HStack(spacing: 4) {
                    Text(entry.time)
                    if let location = entry.location {
                        Text("•")
                        Text(location)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: isCompact ? 11 : 11, weight: .semibold))
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
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: PrototypeEntryRowContentHeightPreferenceKey.self, value: proxy.size.height)
                }
            }
            .onPreferenceChange(PrototypeEntryRowContentHeightPreferenceKey.self) { height in
                rowContentHeight = height
            }

            Spacer(minLength: 0)

            if let trailingCoverImageName {
                inlineCoverPanel(imageName: trailingCoverImageName)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: isCompact ? 10 : 11, weight: .bold))
                .foregroundStyle(Color.storyGray.opacity(0.4))
        }
        .padding(.leading, leadingCoverImageName == nil ? compactCardInset : leadingCoverWidth + 12)
        .padding(.trailing, compactCardInset)
        .padding(.vertical, isCompact ? compactCardInset : 14)
    }

    private var compactCardInset: CGFloat {
        isCompact ? 14 : 12
    }

    private func entryCoverPanel(imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: leadingCoverWidth, height: rowHeight)
            .background(Color.homeCardGray)
            .accessibilityHidden(true)
    }

    private func inlineCoverPanel(imageName: String) -> some View {
        let height = isCompact ? thumbnailSize : max(rowContentHeight, 72)
        let width = height * coverAspectRatio(for: imageName)
        let frameWidth = isCompact ? thumbnailSize : width
        let cornerRadius: CGFloat = 8

        return Image(imageName)
            .resizable()
            .aspectRatio(contentMode: isCompact ? .fill : .fit)
            .scaleEffect(isCompact ? 1.28 : 1)
            .frame(width: frameWidth, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            }
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

private struct PrototypeEntryRowContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct PrototypeChapter: Identifiable {
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

    func copy(title: String) -> PrototypeChapter {
        PrototypeChapter(
            title: title,
            subtitle: subtitle,
            color: color,
            symbol: symbol,
            coverImageName: coverImageName,
            kind: kind,
            isFavorite: isFavorite,
            entries: entries
        )
    }

    static let samples: [PrototypeChapter] = [
        PrototypeChapter(
            title: "Everyday Stories",
            subtitle: "Small moments worth remembering",
            color: Color(red: 0.20, green: 0.12, blue: 0.42),
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
            color: Color(red: 0.05, green: 0.09, blue: 0.20),
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
            color: Color(red: 0.31, green: 0.14, blue: 0.56),
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
            color: Color(red: 0.08, green: 0.18, blue: 0.36),
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

enum UserChapterStore {
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

    static func contains(title: String) -> Bool {
        records.contains { $0.title == title }
    }

    static func rename(title oldTitle: String, to newTitle: String) {
        let updatedRecords = records.map { record in
            guard record.title == oldTitle else {
                return record
            }

            return Record(
                title: newTitle,
                subtitle: record.subtitle,
                symbol: record.symbol,
                kind: record.kind
            )
        }

        guard let data = try? JSONEncoder().encode(updatedRecords) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func replace(with chapters: [PrototypeChapter]) {
        let updatedRecords = chapters.map { chapter in
            Record(
                title: chapter.title,
                subtitle: chapter.subtitle,
                symbol: chapter.symbol,
                kind: chapter.kind == .storyboard ? "storyboard" : "journal"
            )
        }

        guard let data = try? JSONEncoder().encode(updatedRecords) else {
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
            return Color(red: 0.05, green: 0.09, blue: 0.20)
        case "moon.stars.fill":
            return Color(red: 0.31, green: 0.14, blue: 0.56)
        case "building.2.fill":
            return Color(red: 0.08, green: 0.18, blue: 0.36)
        case "heart.fill":
            return Color(red: 0.36, green: 0.05, blue: 0.18)
        case "leaf.fill":
            return Color(red: 0.06, green: 0.22, blue: 0.17)
        default:
            return Color(red: 0.20, green: 0.12, blue: 0.42)
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

enum StoryEntryStore {
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

    static func renameChapter(from oldTitle: String, to newTitle: String) {
        let updatedRecords = records.map { record in
            guard record.chapterTitle == oldTitle else {
                return record
            }

            return Record(
                chapterTitle: newTitle,
                weekday: record.weekday,
                day: record.day,
                title: record.title,
                body: record.body,
                time: record.time,
                location: record.location
            )
        }

        guard let data = try? JSONEncoder().encode(updatedRecords) else {
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

struct PrototypeEntry: Identifiable {
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

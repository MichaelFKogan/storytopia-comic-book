import SwiftUI
import UIKit

struct JournalView: View {
    @Binding var selectedPage: StoryPage
    @Binding var isDraftSaved: Bool
    @Binding var activeDraftID: UUID?

    @State private var selectedFilter = "All"
    @State private var searchText = ""
    @State private var showsPrototypeData = true
    @State private var chapters: [PrototypeChapter]
    @State private var isShowingNewChapter = false
    @State private var savedDrafts: [CreateEntryDraft]
    @State private var isEditingItems = false
    @State private var selectedChapterIDs: Set<UUID> = []
    @State private var selectedDraftIDs: Set<UUID> = []
    @State private var isConfirmingSelectedDeletion = false

    private let filters = ["All", "Journal", "Storyboards", "Favorites"]

    init(
        selectedPage: Binding<StoryPage>,
        isDraftSaved: Binding<Bool>,
        activeDraftID: Binding<UUID?>
    ) {
        _selectedPage = selectedPage
        _isDraftSaved = isDraftSaved
        _activeDraftID = activeDraftID
        _savedDrafts = State(initialValue: CreateEntryDraftStore.loadAll())
        let visibleSamples = PrototypeChapter.samples.filter {
            !DeletedSampleChapterStore.contains(title: $0.title)
        }
        let chapters = UserChapterStore.load() + visibleSamples
        _chapters = State(
            initialValue: chapters.map { chapter in
                var chapter = chapter
                chapter.entries = StoryEntryStore.load(for: chapter.title) + chapter.entries
                return chapter
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                journalBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        header
                        searchField
                        filterTabs
                        savedDraftsSection

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

                if isEditingItems {
                    selectionBar
                        .padding(.bottom, 72)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingNewChapter) {
                NewChapterSheet { chapter in
                    chapters.insert(chapter, at: 0)
                    UserChapterStore.add(chapter)
                    showsPrototypeData = true
                    selectedFilter = "All"
                    searchText = ""
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert("Delete Selected Items?", isPresented: $isConfirmingSelectedDeletion) {
                Button("Delete", role: .destructive) {
                    deleteSelectedItems()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\(selectedItemCount) selected \(selectedItemCount == 1 ? "item" : "items") will be permanently deleted.")
            }
        }
        .onAppear {
            savedDrafts = CreateEntryDraftStore.loadAll()
            isDraftSaved = !savedDrafts.isEmpty
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Stories")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Button(isEditingItems ? "Done" : "Edit") {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isEditingItems.toggle()
                    if !isEditingItems {
                        selectedChapterIDs.removeAll()
                        selectedDraftIDs.removeAll()
                    }
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.storyPurple)

            if !isEditingItems {
                Button {
                    isShowingNewChapter = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 31, height: 31)
                        .background(Color.storyPurple, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Create a new chapter")
            }

            if !isEditingItems {
                Menu {
                    Button {
                        showsPrototypeData = true
                    } label: {
                        Label("Show Sample Chapters", systemImage: "books.vertical")
                    }

                    Button {
                        showsPrototypeData = false
                    } label: {
                        Label("Show Empty State", systemImage: "rectangle.dashed")
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.storyInk)
                        .frame(width: 31, height: 31)
                        .background(Color.white.opacity(0.76), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.storyInk.opacity(0.7), lineWidth: 1.5)
                        )
                }
                .accessibilityLabel("Chapter display options")
            }
        }
        .padding(.top, 12)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.storyGray.opacity(0.76))

            TextField("Search entries...", text: $searchText)
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
        .frame(height: 39)
        .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.44), lineWidth: 1)
        )
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(selectedFilter == filter ? .white : Color.storyInk.opacity(0.85))
                            .padding(.horizontal, 13)
                            .frame(height: 34)
                            .background(
                                selectedFilter == filter ? Color.storyPurple : Color.white.opacity(0.7),
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(selectedFilter == filter ? Color.storyPurple : Color.storyBorder.opacity(0.78), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
                        .foregroundStyle(Color.storyPurple)
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
            if isEditingItems {
                toggleSelection(draftID: draft.id)
            } else {
                activeDraftID = draft.id
                selectedPage = .create
            }
        } label: {
            HStack(spacing: 12) {
                if isEditingItems {
                    selectionIndicator(isSelected: selectedDraftIDs.contains(draft.id))
                }

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
                    .foregroundStyle(Color.storyPurple)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.storyGray.opacity(0.52))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.storyPurple.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
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
                .fill(Color.storyLavender.opacity(0.72))
                .frame(width: 58, height: 70)
                .overlay {
                    Image(systemName: "doc.text")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.storyPurple)
                }
        }
    }

    private var noSavedDrafts: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 20))
                .foregroundStyle(Color.storyPurple.opacity(0.7))

            Text("Drafts you save while creating a story will appear here.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.storyGray)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private var noDraftSearchResults: some View {
        Text("No saved drafts match your search.")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.storyGray)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
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
                .foregroundStyle(Color.storyPurple)

            Text("Previewing sample chapters")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.storyInk.opacity(0.72))

            Spacer()

            Button("Show empty") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsPrototypeData = false
                }
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.storyPurple)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Color.storyLavender.opacity(0.48), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .lastTextBaseline) {
                Text("Your Stories")
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Text("\(filteredChapters.count) books")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.storyGray)
            }
            .padding(.top, 2)

            if filteredChapters.isEmpty {
                noSearchResults
            } else {
                ForEach(filteredChapters) { chapter in
                    Group {
                        if isEditingItems {
                            Button {
                                toggleSelection(chapterID: chapter.id)
                            } label: {
                                HStack(spacing: 10) {
                                    selectionIndicator(isSelected: selectedChapterIDs.contains(chapter.id))
                                    PrototypeChapterRow(chapter: chapter)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                PrototypeChapterDetailView(chapter: chapter) { entry in
                                    guard let chapterIndex = chapters.firstIndex(where: { $0.id == chapter.id }) else {
                                        return
                                    }

                                    chapters[chapterIndex].entries.insert(entry, at: 0)
                                    StoryEntryStore.add(entry, to: chapter.title)
                                }
                            } label: {
                                PrototypeChapterRow(chapter: chapter)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var selectedItemCount: Int {
        selectedChapterIDs.count + selectedDraftIDs.count
    }

    private var selectionBar: some View {
        HStack {
            Text("\(selectedItemCount) selected")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Button(role: .destructive) {
                isConfirmingSelectedDeletion = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.system(size: 13, weight: .bold))
            }
            .disabled(selectedItemCount == 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(isSelected ? Color.storyPurple : Color.storyGray.opacity(0.55))
    }

    private func toggleSelection(chapterID: UUID) {
        if selectedChapterIDs.contains(chapterID) {
            selectedChapterIDs.remove(chapterID)
        } else {
            selectedChapterIDs.insert(chapterID)
        }
    }

    private func toggleSelection(draftID: UUID) {
        if selectedDraftIDs.contains(draftID) {
            selectedDraftIDs.remove(draftID)
        } else {
            selectedDraftIDs.insert(draftID)
        }
    }

    private func deleteSelectedItems() {
        let chaptersToDelete = chapters.filter { selectedChapterIDs.contains($0.id) }
        chaptersToDelete.forEach(deleteChapter)

        let draftsToDelete = savedDrafts.filter { selectedDraftIDs.contains($0.id) }
        draftsToDelete.forEach(deleteDraft)

        selectedChapterIDs.removeAll()
        selectedDraftIDs.removeAll()
        isEditingItems = false
    }

    private func deleteChapter(_ chapter: PrototypeChapter) {
        withAnimation(.easeInOut(duration: 0.2)) {
            chapters.removeAll { $0.id == chapter.id }
        }

        UserChapterStore.delete(title: chapter.title)
        StoryEntryStore.deleteAll(for: chapter.title)

        if PrototypeChapter.samples.contains(where: { $0.title == chapter.title }) {
            DeletedSampleChapterStore.add(title: chapter.title)
        }

    }

    private var filteredChapters: [PrototypeChapter] {
        chapters.filter { chapter in
            let matchesSearch = searchText.isEmpty
                || chapter.title.localizedCaseInsensitiveContains(searchText)
                || chapter.subtitle.localizedCaseInsensitiveContains(searchText)
                || chapter.entries.contains {
                    $0.title.localizedCaseInsensitiveContains(searchText)
                        || $0.body.localizedCaseInsensitiveContains(searchText)
                }

            let matchesFilter: Bool
            switch selectedFilter {
            case "Journal":
                matchesFilter = chapter.kind == .journal
            case "Storyboards":
                matchesFilter = chapter.kind == .storyboard
            case "Favorites":
                matchesFilter = chapter.isFavorite
            default:
                matchesFilter = true
            }

            return matchesSearch && matchesFilter
        }
    }

    private var noSearchResults: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(Color.storyPurple.opacity(0.6))

            Text("No matching chapters")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Text("Try another search or filter.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.storyGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .background(Color.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    .foregroundStyle(Color.storyInk.opacity(0.76))
            }

            Button {
                selectedPage = .create
            } label: {
                Label("Write Your First Entry", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 39)
                    .background(Color.storyPurple, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.top, 10)

            Button("Preview sample chapters") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsPrototypeData = true
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color.storyPurple)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private var journalBackground: some View {
        LinearGradient(
            colors: [Color.storyCream, .white, Color.storyBlush],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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

private struct NewChapterSheet: View {
    private struct CoverOption: Identifiable {
        let id: String
        let symbol: String
        let color: Color
    }

    let onCreate: (PrototypeChapter) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var subtitle = ""
    @State private var kind: PrototypeChapter.Kind = .journal
    @State private var selectedCoverID = "sparkles"
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case subtitle
    }

    private let coverOptions = [
        CoverOption(id: "sparkles", symbol: "sparkles", color: Color(red: 0.34, green: 0.55, blue: 0.92)),
        CoverOption(id: "sun", symbol: "sun.max.fill", color: Color(red: 0.97, green: 0.62, blue: 0.28)),
        CoverOption(id: "moon", symbol: "moon.stars.fill", color: Color(red: 0.43, green: 0.38, blue: 0.78)),
        CoverOption(id: "places", symbol: "building.2.fill", color: Color(red: 0.29, green: 0.70, blue: 0.65)),
        CoverOption(id: "heart", symbol: "heart.fill", color: Color.storyRose),
        CoverOption(id: "leaf", symbol: "leaf.fill", color: Color(red: 0.35, green: 0.64, blue: 0.43))
    ]

    private var selectedCover: CoverOption {
        coverOptions.first { $0.id == selectedCoverID } ?? coverOptions[0]
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedSubtitle: String {
        subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.storyCream, .white, Color.storyBlush],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        coverPreview
                        chapterDetails
                        chapterType
                        coverPicker
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createChapter()
                    }
                    .fontWeight(.bold)
                    .disabled(trimmedTitle.isEmpty)
                }
            }
            .onAppear {
                focusedField = .title
            }
        }
    }

    private var coverPreview: some View {
        HStack(spacing: 18) {
            NotebookCover(
                color: selectedCover.color,
                symbol: selectedCover.symbol,
                imageName: nil,
                width: 72,
                height: 90
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(trimmedTitle.isEmpty ? "Your new chapter" : trimmedTitle)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Text(trimmedSubtitle.isEmpty ? "A place for the stories that belong together." : trimmedSubtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.storyGray)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(selectedCover.color.opacity(0.22), lineWidth: 1)
        )
    }

    private var chapterDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Chapter details")

            VStack(spacing: 0) {
                TextField("Chapter title", text: $title)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .subtitle
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 50)

                Divider()
                    .padding(.leading, 14)

                TextField("Short description (optional)", text: $subtitle)
                    .focused($focusedField, equals: .subtitle)
                    .submitLabel(.done)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.storyInk)
            .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var chapterType: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Chapter type")

            Picker("Chapter type", selection: $kind) {
                Text("Journal").tag(PrototypeChapter.Kind.journal)
                Text("Storyboard").tag(PrototypeChapter.Kind.storyboard)
            }
            .pickerStyle(.segmented)
        }
    }

    private var coverPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Cover")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(coverOptions) { option in
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            selectedCoverID = option.id
                        }
                    } label: {
                        NotebookCover(
                            color: option.color,
                            symbol: option.symbol,
                            imageName: nil,
                            width: 54,
                            height: 68
                        )
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedCoverID == option.id ? option.color.opacity(0.12) : Color.white.opacity(0.7),
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(
                                    selectedCoverID == option.id ? option.color : Color.storyBorder.opacity(0.4),
                                    lineWidth: selectedCoverID == option.id ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select \(option.id) cover")
                    .accessibilityAddTraits(selectedCoverID == option.id ? .isSelected : [])
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold, design: .serif))
            .foregroundStyle(Color.storyInk)
    }

    private func createChapter() {
        guard !trimmedTitle.isEmpty else {
            return
        }

        onCreate(
            PrototypeChapter(
                title: trimmedTitle,
                subtitle: trimmedSubtitle.isEmpty ? "A new collection of stories" : trimmedSubtitle,
                color: selectedCover.color,
                symbol: selectedCover.symbol,
                coverImageName: nil,
                kind: kind,
                isFavorite: false,
                entries: []
            )
        )
        dismiss()
    }
}

private struct PrototypeChapterRow: View {
    let chapter: PrototypeChapter

    private var imageNames: [String] {
        chapter.entries.flatMap(\.imageNames)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            if imageNames.isEmpty {
                NotebookCover(
                    color: chapter.color,
                    symbol: chapter.symbol,
                    imageName: chapter.coverImageName,
                    width: 44,
                    height: 54
                )
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(chapter.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.storyInk)
                        .lineLimit(1)

                    if chapter.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.storyRose)
                    }

                    Spacer(minLength: 4)
                }

                if !imageNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 2) {
                            ForEach(Array(imageNames.enumerated()), id: \.offset) { index, imageName in
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(
                                        width: thumbnailWidth(for: imageName),
                                        height: 104
                                    )
                                    .accessibilityLabel("Story image \(index + 1) of \(imageNames.count)")
                            }
                        }
                    }
                    .frame(height: 104)
                } else {
                    Text(chapter.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.storyInk.opacity(0.58))
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .padding(.trailing, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.44), lineWidth: 1)
        )
        .overlay(alignment: .trailing) {
            HStack(spacing: 8) {
                Text("\(chapter.entries.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.storyInk.opacity(0.5))

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.storyGray.opacity(0.42))
            }
                .padding(.trailing, 11)
        }
        .shadow(color: .black.opacity(0.045), radius: 8, y: 3)
    }

    private func thumbnailWidth(for imageName: String) -> CGFloat {
        guard let image = UIImage(named: imageName), image.size.height > 0 else {
            return 72
        }

        return 104 * (image.size.width / image.size.height)
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
    @State private var chapter: PrototypeChapter
    let onCreateStory: (PrototypeEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection = "Media"
    @State private var isShowingNewStory = false
    @State private var selectedMediaIndex: Int?

    private let sections = ["Media", "Entries"]

    private var mediaImageNames: [String] {
        chapter.entries.flatMap(\.imageNames)
    }

    init(chapter: PrototypeChapter, onCreateStory: @escaping (PrototypeEntry) -> Void) {
        _chapter = State(initialValue: chapter)
        self.onCreateStory = onCreateStory
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    chapter.color.opacity(0.28),
                    Color.storyCream,
                    Color.storyBlush.opacity(0.62)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                detailHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        chapterSummary
                        sectionPicker

                        if selectedSection == "Entries" {
                            entriesList
                        } else {
                            mediaGrid
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingNewStory) {
            NewStorySheet(chapterTitle: chapter.title, accentColor: chapter.color) { entry in
                chapter.entries.insert(entry, at: 0)
                selectedSection = "Entries"
                onCreateStory(entry)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
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
                    accentColor: chapter.color
                )
            }
        }
    }

    private var detailHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.storyInk)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.78), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(chapter.title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)
                .lineLimit(1)

            Spacer()

            Button {
                isShowingNewStory = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(chapter.color, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create a new story")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var chapterSummary: some View {
        HStack(spacing: 16) {
            NotebookCover(
                color: chapter.color,
                symbol: chapter.symbol,
                imageName: chapter.coverImageName,
                width: 58,
                height: 72
            )
            .scaleEffect(1.14)
            .frame(width: 68, height: 82)

            VStack(alignment: .leading, spacing: 6) {
                Text(chapter.title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Text(chapter.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.storyGray)

                Text("\(chapter.entryCountText)  •  \(chapter.imageCount) photos")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.storyInk.opacity(0.64))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(chapter.color.opacity(0.25), lineWidth: 1)
        )
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
                            .foregroundStyle(selectedSection == section ? Color.storyInk : Color.storyGray.opacity(0.64))

                        Capsule()
                            .fill(selectedSection == section ? chapter.color : Color.clear)
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
                        .foregroundStyle(chapter.color.opacity(0.72))

                    Text("No stories yet")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)

                    Text("Begin this chapter with its first story.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.storyGray)
                        .multilineTextAlignment(.center)

                    Button {
                        isShowingNewStory = true
                    } label: {
                        Label("Write the First Story", systemImage: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 40)
                            .background(chapter.color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(chapter.entries.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            PrototypeEntryDetailView(entry: entry, chapter: chapter)
                        } label: {
                            PrototypeEntryRow(entry: entry, accentColor: chapter.color)
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
        .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.38), lineWidth: 1)
        )
    }

    private var mediaGrid: some View {
        Group {
            if mediaImageNames.isEmpty {
                Text("No photos yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.storyGray)
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
    let onCreate: (PrototypeEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var location = ""
    @State private var storyDate = Date()
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

    var body: some View {
        NavigationStack {
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
            .onAppear {
                isTitleFocused = true
            }
            .navigationDestination(isPresented: $isShowingExpandedEditor) {
                ExpandedEntryEditor(entryText: $bodyText, storyTitle: $title)
            }
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

                Text("Chapter")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.storyInk.opacity(0.9))
                    .frame(width: 72, alignment: .leading)

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

            DatePicker(selection: $storyDate, displayedComponents: [.date, .hourAndMinute]) {
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

    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite = false
    @State private var selectedImageName: String?

    var body: some View {
        ZStack {
            storyDetailBackground

            VStack(spacing: 0) {
                entryHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        entryIntroduction

                        if !entry.imageNames.isEmpty {
                            photoStory
                        }

                        journalPage
                        entryDetails
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
                }
                .background(Color.clear)
            }
        }
        .background(storyDetailBackground)
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
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
                PhotoViewer(imageName: selectedImageName, accentColor: chapter.color)
            }
        }
    }

    private var storyDetailBackground: some View {
        ZStack {
            Color.storyCream

            LinearGradient(
                colors: [
                    chapter.color.opacity(0.24),
                    Color.storyCream,
                    Color.storyBlush.opacity(0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var entryHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.storyInk)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.82), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to \(chapter.title)")

            Spacer()

            Text("Story")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.storyInk)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.82), in: Circle())
            }
            .accessibilityLabel("Story options")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var entryIntroduction: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                VStack(spacing: 1) {
                    Text(entry.weekday)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(chapter.color)

                    Text(entry.day)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)
                }
                .frame(width: 48, height: 54)
                .background(chapter.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(chapter.color)

                    Text(entry.time)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.storyGray)
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
                        .background(Color.white.opacity(0.72), in: Circle())
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
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(chapter.color.opacity(0.2), lineWidth: 1)
        )
    }

    private var photoStory: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The moment")
                .font(.system(size: 19, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            if let firstImageName = entry.imageNames.first {
                Button {
                    selectedImageName = firstImageName
                } label: {
                    Image(firstImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: entry.imageNames.count == 1 ? 240 : 205)
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

            if entry.imageNames.count > 1 {
                HStack(spacing: 8) {
                    ForEach(Array(entry.imageNames.dropFirst().prefix(3)), id: \.self) { imageName in
                        Button {
                            selectedImageName = imageName
                        } label: {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 78)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var journalPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("My story", systemImage: "text.quote")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(chapter.color)

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
                .fill(chapter.color.opacity(0.18))
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
                Color.white.opacity(0.88)

                VStack(spacing: 27) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(chapter.color.opacity(0.07))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 28)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.46), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.045), radius: 10, y: 4)
    }

    private var entryDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Story details")
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            HStack(spacing: 10) {
                DetailPill(systemName: "clock", text: entry.time, color: chapter.color)

                if let location = entry.location {
                    DetailPill(systemName: "location", text: location, color: chapter.color)
                }
            }
        }
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
            imageView.heightAnchor.constraint(
                equalTo: imageView.widthAnchor,
                multiplier: image.size.height / image.size.width
            ).isActive = true
            stackView.addArrangedSubview(imageView)
            return imageView
        }

        DispatchQueue.main.async {
            context.coordinator.scrollToInitialImage(in: scrollView)
        }

        return scrollView
    }

    private func makeImageBoundary(nextIndex _: Int, totalCount _: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.035, alpha: 1)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 29).isActive = true

        return container
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableVerticalComicView
        weak var stackView: UIStackView?
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
                imageViews.indices.contains(parent.initialIndex)
            else {
                return
            }

            scrollView.layoutIfNeeded()
            stackView?.layoutIfNeeded()

            let imageView = imageViews[parent.initialIndex]
            let targetY = max(
                0,
                imageView.frame.midY - (scrollView.bounds.height / 2)
            )
            scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
            didScrollToInitialImage = true
            updateVisibleIndex(in: scrollView)
        }

        private func updateVisibleIndex(in scrollView: UIScrollView) {
            guard !imageViews.isEmpty else {
                return
            }

            let viewportCenterY = scrollView.contentOffset.y + (scrollView.bounds.height / 2)
            let zoomScale = scrollView.zoomScale
            let closestIndex = imageViews.indices.min { left, right in
                abs((imageViews[left].frame.midY * zoomScale) - viewportCenterY)
                    < abs((imageViews[right].frame.midY * zoomScale) - viewportCenterY)
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(2)

                Text(entry.body)
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(2)
                    .foregroundStyle(Color.storyInk.opacity(0.74))
                    .lineLimit(3)

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

                if !entry.imageNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 7) {
                            ForEach(Array(entry.imageNames.enumerated()), id: \.offset) { index, imageName in
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 58, height: 58)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
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

struct StoriesListView: View {
    @Binding var selectedPage: StoryPage
    @Binding var isDraftSaved: Bool
    @Binding var activeDraftID: UUID?

    @State private var chapters: [PrototypeChapter] = []
    @State private var savedDrafts: [CreateEntryDraft] = []
    @State private var isShowingNewChapter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Stories List")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)

                    Spacer()

                    EditButton()
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.storyPurple)

                    Button {
                        isShowingNewChapter = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 31, height: 31)
                            .background(Color.storyPurple, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Create a new story collection")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                List {
                    draftsSection
                    storiesSection
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(listBackground)
                .refreshable {
                    reloadContent()
                }

                BottomNavigationBar(selectedPage: $selectedPage)
            }
            .background(listBackground)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingNewChapter) {
                NewChapterSheet { chapter in
                    chapters.insert(chapter, at: 0)
                    UserChapterStore.add(chapter)
                    StoriesListOrderStore.saveChapterOrder(chapters.map(\.title))
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            reloadContent()
        }
    }

    private var draftsSection: some View {
        Section {
            if let mostRecentDraft {
                Button {
                    activeDraftID = mostRecentDraft.id
                    selectedPage = .create
                } label: {
                    StoriesListDraftRow(draft: mostRecentDraft)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteDraft(mostRecentDraft)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            } else {
                Text("No saved drafts")
                    .foregroundStyle(.secondary)
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            }
        } header: {
            HStack {
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
                        Text("View All")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .textCase(nil)
        }
    }

    @ViewBuilder
    private var storiesSection: some View {
        Section {
            if chapters.isEmpty {
                StoriesListEmptyRow(isSearching: false)
            } else {
                ForEach(chapters) { chapter in
                    NavigationLink {
                        PrototypeChapterDetailView(chapter: chapter) { entry in
                            guard let chapterIndex = chapters.firstIndex(where: { $0.id == chapter.id }) else {
                                return
                            }

                            chapters[chapterIndex].entries.insert(entry, at: 0)
                            StoryEntryStore.add(entry, to: chapter.title)
                        }
                    } label: {
                        StoriesListChapterRow(chapter: chapter)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteChapter(chapter)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                }
                .onDelete(perform: deleteChapters)
                .onMove(perform: moveChapters)
            }
        } header: {
            HStack {
                Text("Your Stories")
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Text("\(chapters.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.storyGray)
            }
            .textCase(nil)
        }
    }

    private var listBackground: some View {
        LinearGradient(
            colors: [Color.storyCream, .white, Color.storyBlush.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var mostRecentDraft: CreateEntryDraft? {
        savedDrafts.first
    }

    private func reloadContent() {
        let visibleSamples = PrototypeChapter.samples.filter {
            !DeletedSampleChapterStore.contains(title: $0.title)
        }

        let loadedChapters = (UserChapterStore.load() + visibleSamples).map { chapter in
            var chapter = chapter
            chapter.entries = StoryEntryStore.load(for: chapter.title) + chapter.entries
            return chapter
        }
        chapters = StoriesListOrderStore.sortChapters(loadedChapters)
        savedDrafts = CreateEntryDraftStore.loadAll()
        isDraftSaved = !savedDrafts.isEmpty
    }

    private func deleteDraft(_ draft: CreateEntryDraft) {
        CreateEntryDraftStore.delete(id: draft.id)
        savedDrafts.removeAll { $0.id == draft.id }
        if activeDraftID == draft.id {
            activeDraftID = nil
        }
        isDraftSaved = !savedDrafts.isEmpty
    }

    private func deleteChapters(at offsets: IndexSet) {
        let chaptersToDelete = offsets.map { chapters[$0] }
        chaptersToDelete.forEach(deleteChapter)
    }

    private func deleteChapter(_ chapter: PrototypeChapter) {
        withAnimation {
            chapters.removeAll { $0.id == chapter.id }
        }
        StoriesListOrderStore.saveChapterOrder(chapters.map(\.title))

        UserChapterStore.delete(title: chapter.title)
        StoryEntryStore.deleteAll(for: chapter.title)

        if PrototypeChapter.samples.contains(where: { $0.title == chapter.title }) {
            DeletedSampleChapterStore.add(title: chapter.title)
        }
    }

    private func moveChapters(from source: IndexSet, to destination: Int) {
        chapters.move(fromOffsets: source, toOffset: destination)
        StoriesListOrderStore.saveChapterOrder(chapters.map(\.title))
    }
}

private enum StoriesListOrderStore {
    private static let chapterOrderKey = "StorytopiaStoriesListChapterOrder"

    static func sortChapters(_ chapters: [PrototypeChapter]) -> [PrototypeChapter] {
        let savedOrder = UserDefaults.standard.stringArray(forKey: chapterOrderKey) ?? []
        return sorted(chapters, savedKeys: savedOrder, key: \.title)
    }

    static func saveChapterOrder(_ titles: [String]) {
        UserDefaults.standard.set(titles, forKey: chapterOrderKey)
    }

    private static func sorted<Value>(
        _ values: [Value],
        savedKeys: [String],
        key: (Value) -> String
    ) -> [Value] {
        let positions = Dictionary(uniqueKeysWithValues: savedKeys.enumerated().map { ($0.element, $0.offset) })
        let savedValues = values
            .filter { positions[key($0)] != nil }
            .sorted { positions[key($0), default: .max] < positions[key($1), default: .max] }
        let newValues = values.filter { positions[key($0)] == nil }
        return newValues + savedValues
    }
}

private struct StoriesListDraftRow: View {
    let draft: CreateEntryDraft

    var body: some View {
        HStack(spacing: 10) {
            thumbnail

            Text(draftDisplayTitle(draft))
                .font(.body.weight(.medium))
                .foregroundStyle(Color.storyInk)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(draft.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 1)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = draft.photos.first {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.storyLavender)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "doc.text")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.storyPurple)
                }
        }
    }
}

private struct StoriesListChapterRow: View {
    let chapter: PrototypeChapter

    var body: some View {
        HStack(spacing: 10) {
            NotebookCover(
                color: chapter.color,
                symbol: chapter.symbol,
                imageName: chapter.coverImageName,
                width: 30,
                height: 36
            )

            Text(chapter.title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.storyInk)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("\(chapter.entries.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct StoriesListEmptyRow: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isSearching ? "text.magnifyingglass" : "books.vertical")
                .font(.system(size: 28))
                .foregroundStyle(Color.storyPurple.opacity(0.7))

            Text(isSearching ? "No matching stories" : "No stories yet")
                .font(.headline)
                .foregroundStyle(Color.storyInk)

            Text(isSearching ? "Try another search or filter." : "Tap + to create your first story collection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .listRowBackground(Color.white.opacity(0.65))
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

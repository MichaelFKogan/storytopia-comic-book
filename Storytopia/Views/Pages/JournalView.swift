import SwiftUI

struct JournalView: View {
    @Binding var selectedPage: StoryPage

    @State private var selectedFilter = "All"
    @State private var searchText = ""
    @State private var showsPrototypeData = true
    @State private var chapters: [PrototypeChapter]
    @State private var isShowingNewChapter = false

    private let filters = ["All", "Journal", "Storyboards", "Favorites"]

    init(selectedPage: Binding<StoryPage>) {
        _selectedPage = selectedPage
        _chapters = State(
            initialValue: UserChapterStore.load() + PrototypeChapter.samples
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
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Chapters")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

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
        HStack(spacing: 7) {
            ForEach(filters, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(selectedFilter == filter ? .white : Color.storyInk.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 8)
                        .frame(height: 34)
                        .frame(maxWidth: .infinity)
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
                Text("Your Chapters")
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
                    NavigationLink {
                        PrototypeChapterDetailView(chapter: chapter)
                    } label: {
                        PrototypeChapterRow(chapter: chapter)
                    }
                    .buttonStyle(.plain)
                }
            }
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

    var body: some View {
        HStack(spacing: 14) {
            NotebookCover(
                color: chapter.color,
                symbol: chapter.symbol,
                imageName: chapter.coverImageName
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(chapter.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.storyInk)
                        .lineLimit(1)

                    if chapter.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.storyRose)
                    }
                }

                HStack(spacing: 10) {
                    Label(chapter.entryCountText, systemImage: "doc.text")

                    if chapter.imageCount > 0 {
                        Label("\(chapter.imageCount)", systemImage: "photo")
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.storyInk.opacity(0.58))
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.storyGray.opacity(0.52))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.44), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.045), radius: 8, y: 3)
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
    let chapter: PrototypeChapter

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection = "Entries"

    private let sections = ["Entries", "Media"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [chapter.color.opacity(0.14), Color.white, Color.storyBlush.opacity(0.36)],
                startPoint: .top,
                endPoint: .bottom
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
        .toolbar(.hidden, for: .navigationBar)
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
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.storyInk)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.78), in: Circle())
            }
            .buttonStyle(.plain)
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
        .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.38), lineWidth: 1)
        )
    }

    private var mediaGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(chapter.entries.flatMap(\.imageNames), id: \.self) { imageName in
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
        }
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
            LinearGradient(
                colors: [
                    chapter.color.opacity(0.14),
                    Color.storyCream,
                    Color.storyBlush.opacity(0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
            }
        }
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

            Text("Journal Entry")
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
                    Label("Edit Entry", systemImage: "pencil")
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
            .accessibilityLabel("Entry options")
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
            Text("Entry details")
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
                    HStack(spacing: 6) {
                        ForEach(entry.imageNames.prefix(3), id: \.self) { imageName in
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 58, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        }

                        if entry.imageNames.count > 3 {
                            Text("+\(entry.imageNames.count - 3)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.storyInk.opacity(0.78), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
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
    let entries: [PrototypeEntry]

    var imageCount: Int {
        entries.reduce(0) { $0 + $1.imageNames.count }
    }

    var entryCountText: String {
        "\(entries.count) \(entries.count == 1 ? "entry" : "entries")"
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
                    imageNames: ["storyboard_placeholder_1", "storyboard_placeholder_2"]
                ),
                PrototypeEntry(
                    weekday: "SUN",
                    day: "14",
                    title: "Sunday dinner",
                    body: "We stayed at the table long after dessert and retold the same family stories.",
                    time: "8:04 PM",
                    location: "Home",
                    imageNames: ["storyboard_placeholder_3"]
                ),
                PrototypeEntry(
                    weekday: "FRI",
                    day: "05",
                    title: "The first warm night",
                    body: "Everyone seemed to have the same idea: walk slowly and stay outside.",
                    time: "10:18 PM",
                    location: nil,
                    imageNames: []
                )
            ]
        ),
        PrototypeChapter(
            title: "Summer Adventures",
            subtitle: "Trips, detours, and sunlit days",
            color: Color(red: 0.97, green: 0.62, blue: 0.28),
            symbol: "sun.max.fill",
            coverImageName: "storyboard_placeholder_4",
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
                    imageNames: ["storyboard_placeholder_4", "storyboard_placeholder_5", "art_style_pop_art", "art_style_anime"]
                ),
                PrototypeEntry(
                    weekday: "MON",
                    day: "01",
                    title: "Boardwalk at sunset",
                    body: "The sky turned peach just as the lights came on.",
                    time: "7:31 PM",
                    location: "Asbury Park, NJ",
                    imageNames: ["homepage_banner", "art_style_colored_journal"]
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
                    imageNames: ["art_style_manga"]
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
                    imageNames: ["art_style_graphic_novel", "art_style_cozy_storybook"]
                ),
                PrototypeEntry(
                    weekday: "TUE",
                    day: "12",
                    title: "The corner flower stand",
                    body: "He remembered everyone's favorite color.",
                    time: "11:03 AM",
                    location: "Chelsea",
                    imageNames: []
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

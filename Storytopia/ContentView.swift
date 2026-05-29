//
//  ContentView.swift
//  Storytopia
//
//  Created by Mike Kogan on 5/28/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedPage: StoryPage = .home
    @State private var entryText = ""

    var body: some View {
        Group {
            switch selectedPage {
            case .home:
                homePage
            case .explore:
                ExploreView(selectedPage: $selectedPage)
            case .create:
                CreateEntryView(
                    entryText: $entryText,
                    selectedPage: $selectedPage
                )
            case .journal:
                JournalView(selectedPage: $selectedPage)
            case .profile:
                ProfileView(selectedPage: $selectedPage)
            }
        }
    }

    private var homePage: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.storyCream, .white, Color.storyBlush],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    heroCard
                    captureCard
                    storyboardsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 92)
            }

            bottomNavigation
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Storytopia")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Text("Your life, told in storyboards.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.storyGray)
            }

            Spacer()

            HStack(spacing: 10) {
                CircleIconButton(systemName: "bell")
                ProfilePlaceholder()
            }
            .padding(.top, 5)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Create your\nfirst story")
                .font(.system(size: 25, weight: .bold, design: .serif))
                .lineSpacing(2)
                .foregroundStyle(Color.storyInk)
                .fixedSize(horizontal: false, vertical: true)

            Text("Write about your day \nand turn it into a story.")
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(2)
                .foregroundStyle(Color.storyGray)

            Button {
                selectedPage = .create
            } label: {
                Label("New Story", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Color.storyPurple, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 172, alignment: .leading)
        .background {
            Image("homepage_banner")
                .resizable()
                .scaledToFill()
                .overlay(
                    LinearGradient(
                        colors: [.white.opacity(0.82), .white.opacity(0.38), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.storyBorder, lineWidth: 1)
        )
        .shadow(color: Color.storyPurple.opacity(0.08), radius: 12, y: 7)
    }

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capture this moment")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.storyInk)

                    Text("No labels needed. AI will understand.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.storyGray)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.storyPurple.opacity(0.7))
            }

            HStack(spacing: 12) {
                Text("What’s on your mind?")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.storyGray.opacity(0.72))

                Spacer()

                Image(systemName: "mic")
                Image(systemName: "photo")
            }
            .font(.system(size: 19, weight: .regular))
            .foregroundStyle(Color.storyInk)
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(14)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.storyBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
    }

    private var storyboardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Your storyboards", action: "View all")

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.52))

                HStack(spacing: 12) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(Color.storyPurple)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Your storyboards\nwill appear here")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.storyInk)
                            .lineSpacing(2)

                        Text("Start by creating your\nfirst story.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.storyGray)
                            .lineSpacing(2)
                    }
                }
                .padding(.horizontal, 18)
            }
            .frame(height: 128)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.storyBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
        }
    }

    private var bottomNavigation: some View {
        HStack {
            NavItem(title: "Home", systemName: "house.fill", isSelected: selectedPage == .home) {
                selectedPage = .home
            }
            Spacer()
            NavItem(title: "Explore", systemName: "safari", isSelected: selectedPage == .explore) {
                selectedPage = .explore
            }
            Spacer()
            CreateNavItem(isSelected: selectedPage == .create) {
                selectedPage = .create
            }
            Spacer()
            NavItem(title: "Journal", systemName: "book.closed.fill", isSelected: selectedPage == .journal) {
                selectedPage = .journal
            }
            Spacer()
            NavItem(title: "Profile", systemName: "person", isSelected: selectedPage == .profile) {
                selectedPage = .profile
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 9)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.storyBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

private enum StoryPage {
    case home
    case explore
    case create
    case journal
    case profile
}

private struct ExploreView: View {
    @Binding var selectedPage: StoryPage
    @State private var selectedFilter = "For You"

    private let filters = ["For You", "Following", "Popular"]
    private let stories = [
        ExploreStory(
            title: "A quiet morning",
            author: "sunny.days",
            likes: 124,
            comments: 12,
            palette: [.storyGold, .storyPeach, .storyInk],
            layout: .mosaic
        ),
        ExploreStory(
            title: "Rainy day in the city",
            author: "creative.soul",
            likes: 98,
            comments: 8,
            palette: [.storyInk, .blue.opacity(0.62), .storyGray],
            layout: .wide
        ),
        ExploreStory(
            title: "Trip to the mountains",
            author: "wander.with.me",
            likes: 156,
            comments: 15,
            palette: [.green.opacity(0.62), .cyan.opacity(0.56), .storyInk],
            layout: .mosaic
        ),
        ExploreStory(
            title: "Cozy night in",
            author: "story.seeker",
            likes: 112,
            comments: 10,
            palette: [.orange.opacity(0.7), .storyPurple, .storyInk],
            layout: .wide
        )
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.storyCream, .white, Color.storyBlush],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    filterTabs
                    storyGrid
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 92)
            }

            bottomNavigation
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Explore")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Button {
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.storyInk)
                    .frame(width: 38, height: 38)
            }
            .accessibilityLabel("Search explore")
        }
    }

    private var filterTabs: some View {
        HStack(spacing: 12) {
            ForEach(filters, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(selectedFilter == filter ? .white : Color.storyInk.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 13)
                        .frame(height: 28)
                        .background(
                            selectedFilter == filter ? Color.storyPurple : Color.storySoftPink.opacity(0.64),
                            in: Capsule()
                        )
                }
            }

            Spacer()
        }
    }

    private var storyGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(stories) { story in
                ExploreStoryCard(story: story)
            }
        }
    }

    private var bottomNavigation: some View {
        HStack {
            NavItem(title: "Home", systemName: "house", isSelected: selectedPage == .home) {
                selectedPage = .home
            }
            Spacer()
            NavItem(title: "Explore", systemName: "safari.fill", isSelected: selectedPage == .explore) {
                selectedPage = .explore
            }
            Spacer()
            CreateNavItem(isSelected: selectedPage == .create) {
                selectedPage = .create
            }
            Spacer()
            NavItem(title: "Journal", systemName: "book.closed.fill", isSelected: selectedPage == .journal) {
                selectedPage = .journal
            }
            Spacer()
            NavItem(title: "Profile", systemName: "person", isSelected: selectedPage == .profile) {
                selectedPage = .profile
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 9)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.storyBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

private struct ExploreStory: Identifiable {
    enum ThumbnailLayout {
        case mosaic
        case wide
    }

    let title: String
    let author: String
    let likes: Int
    let comments: Int
    let palette: [Color]
    let layout: ThumbnailLayout

    var id: String { title }
}

private struct ExploreStoryCard: View {
    let story: ExploreStory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExploreThumbnail(story: story)
                .frame(height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(story.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.storyInk)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .padding(.horizontal, 8)

            HStack(spacing: 5) {
                Circle()
                    .fill(Color.storyPeach)
                    .frame(width: 13, height: 13)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                    )

                Text(story.author)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.storyGray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 12) {
                Label("\(story.likes)", systemImage: "heart")
                Label("\(story.comments)", systemImage: "bubble.left")
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.storyGray.opacity(0.82))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.bottom, 9)
        }
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 7, y: 4)
    }
}

private struct ExploreThumbnail: View {
    let story: ExploreStory

    var body: some View {
        ZStack {
            LinearGradient(
                colors: story.palette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            switch story.layout {
            case .mosaic:
                mosaic
            case .wide:
                wideScene
            }
        }
    }

    private var mosaic: some View {
        VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { column in
                        vignette(index: row * 3 + column)
                    }
                }
            }
        }
        .padding(3)
    }

    private func vignette(index: Int) -> some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    story.palette[index % story.palette.count].opacity(0.88),
                    story.palette[(index + 1) % story.palette.count].opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.storyInk.opacity(0.58))
                .frame(width: 10, height: 10)
                .offset(y: -10)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.storyInk.opacity(0.5))
                .frame(width: 17, height: 18)
                .offset(y: 6)

            if index.isMultiple(of: 2) {
                Circle()
                    .fill(Color.storyGold.opacity(0.75))
                    .frame(width: 14, height: 14)
                    .offset(x: -14, y: -21)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var wideScene: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [story.palette[0].opacity(0.86), story.palette[1].opacity(0.72), story.palette[2].opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom, spacing: 13) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.storyInk.opacity(0.34))
                        .frame(width: 13 + CGFloat(index % 2) * 5, height: 45 + CGFloat(index) * 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)

            Circle()
                .fill(Color.storyInk.opacity(0.7))
                .frame(width: 18, height: 18)
                .offset(y: -36)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.storyInk.opacity(0.68))
                .frame(width: 25, height: 42)
                .offset(y: -3)

            Circle()
                .stroke(Color.white.opacity(0.48), lineWidth: 2)
                .frame(width: 45, height: 22)
                .offset(y: -44)
        }
    }
}

private struct JournalView: View {
    @Binding var selectedPage: StoryPage
    @State private var selectedFilter = "All"

    private let filters = ["All", "Journal", "Storyboards", "Favorites"]

    var body: some View {
        ZStack(alignment: .bottom) {
            journalBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    header
                    searchField
                    filterTabs
                    emptyState
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 92)
            }

            bottomNavigation
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Journal")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Button {
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
            .accessibilityLabel("Filter journal")
        }
        .padding(.top, 12)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.storyGray.opacity(0.76))

            Text("Search entries...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.storyGray.opacity(0.62))

            Spacer()
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
        HStack(spacing: 10) {
            ForEach(filters, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(selectedFilter == filter ? .white : Color.storyInk.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 14)
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
            }
        }
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
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomNavigation: some View {
        HStack {
            NavItem(title: "Home", systemName: "house", isSelected: selectedPage == .home) {
                selectedPage = .home
            }
            Spacer()
            NavItem(title: "Explore", systemName: "safari", isSelected: selectedPage == .explore) {
                selectedPage = .explore
            }
            Spacer()
            CreateNavItem(isSelected: selectedPage == .create) {
                selectedPage = .create
            }
            Spacer()
            NavItem(title: "Journal", systemName: "book.closed.fill", isSelected: selectedPage == .journal) {
                selectedPage = .journal
            }
            Spacer()
            NavItem(title: "Profile", systemName: "person", isSelected: selectedPage == .profile) {
                selectedPage = .profile
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 9)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.storyBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
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

private struct ProfileView: View {
    @Binding var selectedPage: StoryPage

    private let storyboardColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.storyCream, .white, Color.storyBlush],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 21) {
                    header
                    profileCard
                    storyboardsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }

            bottomNavigation
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Profile")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Text("Your stories, your journey.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.storyGray)
            }

            Spacer()

            HStack(spacing: 10) {
                CircleIconButton(systemName: "bell")
                ProfilePlaceholder()
            }
            .padding(.top, 5)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 15) {
            HStack(alignment: .center, spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    ProfilePlaceholder(size: 62)

                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.storyPurple)
                        .frame(width: 27, height: 27)
                        .background(.white, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.storyBorder.opacity(0.54), lineWidth: 1)
                        )
                        .offset(x: 5, y: 5)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text("Story Seeker")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.storyInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.storyGray)
                    }

                    Text("Collecting life's moments,\none storyboard at a time.")
                        .font(.system(size: 13, weight: .medium))
                        .lineSpacing(2)
                        .foregroundStyle(Color.storyGray)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Button {
                } label: {
                    Text("Edit Profile")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.storyInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 94, height: 42)
                        .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.storyPurple.opacity(0.25), lineWidth: 1.4)
                        )
                }
            }

            HStack(spacing: 0) {
                ProfileStat(systemName: "book.closed", value: "0", title: "Storyboards")
                statDivider
                ProfileStat(systemName: "calendar", value: "0", title: "This Month")
                statDivider
                ProfileStat(systemName: "flame", value: "0", title: "Day Streak")
                statDivider
                ProfileStat(systemName: "heart", value: "0", title: "Favorites")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: Color.storyPurple.opacity(0.05), radius: 14, y: 8)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.storyBorder.opacity(0.52))
            .frame(width: 1, height: 42)
    }

    private var storyboardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Storyboards")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(Color.storyInk)

                    Text("All the storyboards you've created.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.storyGray)
                }

                Spacer()

                Button {
                } label: {
                    HStack(spacing: 7) {
                        Text("View all")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.storyPurple)
                    .frame(height: 32)
                }
            }

            LazyVGrid(columns: storyboardColumns, spacing: 10) {
                ForEach(0..<9, id: \.self) { _ in
                    StoryboardPlaceholderCard()
                }
            }
        }
    }

    private var bottomNavigation: some View {
        HStack {
            NavItem(title: "Home", systemName: "house", isSelected: selectedPage == .home) {
                selectedPage = .home
            }
            Spacer()
            NavItem(title: "Explore", systemName: "safari", isSelected: selectedPage == .explore) {
                selectedPage = .explore
            }
            Spacer()
            CreateNavItem(isSelected: selectedPage == .create) {
                selectedPage = .create
            }
            Spacer()
            NavItem(title: "Journal", systemName: "book.closed.fill", isSelected: selectedPage == .journal) {
                selectedPage = .journal
            }
            Spacer()
            NavItem(title: "Profile", systemName: "person.fill", isSelected: selectedPage == .profile) {
                selectedPage = .profile
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 9)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.storyBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

private struct ProfileStat: View {
    let systemName: String
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.storyGray.opacity(0.82))
                .frame(height: 22)

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.storyGray)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StoryboardPlaceholderCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.38))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.storyBorder.opacity(0.56), lineWidth: 1)
                )

            VStack(spacing: 9) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "photo")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Color.storyPurple.opacity(0.28))

                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.storyPurple.opacity(0.38))
                        .offset(x: 13, y: -8)
                }

                Text("No storyboards yet")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.storyGray.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 136)
    }
}

private struct CreateEntryView: View {
    private let artStyles = ["Comic", "Ghibli", "Pixar", "Manga", "Cinematic", "Pixel Art"]

    @Binding var entryText: String
    @Binding var selectedPage: StoryPage

    @State private var isShowingArtStyles = false
    @State private var selectedArtStyle: String?
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.storyCream, Color.white.opacity(0.94), Color.storyBlush],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .onTapGesture {
                isEditorFocused = false
            }

            VStack(alignment: .leading, spacing: 0) {
                pageHeader

                VStack(alignment: .leading, spacing: 14) {
                    editorCard

                    Button {
                        isEditorFocused = false
                        isShowingArtStyles = true
                    } label: {
                        HStack(spacing: 7) {
                            Text("Generate Storyboard")
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
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

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 92)
            }

            bottomNavigation
        }
        .sheet(isPresented: $isShowingArtStyles) {
            ArtStyleSelectionSheet(
                artStyles: artStyles,
                selectedArtStyle: selectedArtStyle,
                onSelect: { style in
                    selectedArtStyle = style
                    isShowingArtStyles = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var pageHeader: some View {
        HStack(alignment: .center) {
            Text("New Entry")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Button {
            } label: {
                Text("Save")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.storyPurple)
                    .frame(height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var bottomNavigation: some View {
        HStack {
            NavItem(title: "Home", systemName: "house", isSelected: selectedPage == .home) {
                selectedPage = .home
            }
            Spacer()
            NavItem(title: "Explore", systemName: "safari", isSelected: selectedPage == .explore) {
                selectedPage = .explore
            }
            Spacer()
            CreateNavItem(isSelected: selectedPage == .create) {
                selectedPage = .create
            }
            Spacer()
            NavItem(title: "Journal", systemName: "book.closed.fill", isSelected: selectedPage == .journal) {
                selectedPage = .journal
            }
            Spacer()
            NavItem(title: "Profile", systemName: "person", isSelected: selectedPage == .profile) {
                selectedPage = .profile
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 9)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.storyBorder, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Write about your day...")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.storyInk)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $entryText)
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(Color.storyInk.opacity(0.82))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isEditorFocused)
                    .padding(.horizontal, -5)
                    .padding(.vertical, -7)
                    .onTapGesture {
                        isEditorFocused = true
                    }

                if entryText.isEmpty {
                    Text("Today was chaotic but really good...")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.storyGray.opacity(0.46))
                        .padding(.horizontal, 0)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 205)

            Divider()
                .background(Color.storyBorder.opacity(0.7))

            HStack(spacing: 24) {
                Button {
                } label: {
                    Image(systemName: "photo")
                }

                Button {
                } label: {
                    Image(systemName: "mic")
                }

                Spacer()

                Button {
                } label: {
                    Image(systemName: "face.smiling")
                }
            }
            .font(.system(size: 21, weight: .regular))
            .foregroundStyle(Color.storyInk.opacity(0.82))
            .frame(height: 52)
        }
        .padding(16)
        .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
        )
    }
}

private struct ArtStyleSelectionSheet: View {
    let artStyles: [String]
    let selectedArtStyle: String?
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Choose an art style")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color.storyInk)

                    Text("Pick the look for your storyboard.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.storyGray)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.storyInk.opacity(0.72))
                        .frame(width: 34, height: 34)
                        .background(Color.storySoftPink.opacity(0.72), in: Circle())
                }
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(artStyles.enumerated()), id: \.offset) { index, style in
                    Button {
                        onSelect(style)
                    } label: {
                        ArtStyleOptionCard(
                            title: style,
                            index: index,
                            isSelected: selectedArtStyle == style
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 14)
        .background(Color.storyCream.opacity(0.55))
    }
}

private struct ArtStyleOptionCard: View {
    let title: String
    let index: Int
    let isSelected: Bool

    private var colors: [Color] {
        let palette: [[Color]] = [
            [.storyPeach, .storyPurple],
            [.storyGold, .green.opacity(0.45)],
            [.storyInk, .storyPeach],
            [.white, .black.opacity(0.75)],
            [.storyRose, .orange.opacity(0.65)],
            [.brown.opacity(0.7), .storyGold]
        ]
        return palette[index % palette.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(ArtStyleInnerGrid(index: index))
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white, Color.storyPurple)
                            .padding(8)
                    }
                }
                .frame(height: 98)

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.storyPurple : Color.storyBorder.opacity(0.72), lineWidth: isSelected ? 2 : 1)
        )
    }
}

private struct SectionTitle: View {
    let title: String
    let action: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Button(action) {
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.storyPurple)
        }
        .padding(.horizontal, 2)
    }
}

private struct CircleIconButton: View {
    let systemName: String

    var body: some View {
        Button {
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.storyInk)
                .frame(width: 42, height: 42)
                .background(Color.storySoftPink, in: Circle())
        }
    }
}

private struct ProfilePlaceholder: View {
    var size: CGFloat = 42

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.storyPeach, Color.storyPurple.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size * 0.64))
                    .foregroundStyle(.white.opacity(0.85))
            )
            .frame(width: size, height: size)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

private struct ArtStyleInnerGrid: View {
    let index: Int

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<2, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.white.opacity(index == 3 ? 0.66 : 0.22))
                            .overlay(
                                Image(systemName: (row + column).isMultiple(of: 2) ? "person.fill" : "sparkles")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.storyInk.opacity(0.35))
                            )
                    }
                }
            }
        }
        .padding(6)
    }
}

private struct NavItem: View {
    let title: String
    let systemName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 21, weight: isSelected ? .bold : .regular))

                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.82))
            .frame(width: 50, height: 44)
        }
    }
}

private struct CreateNavItem: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "plus.circle.fill" : "plus.circle")
                    .font(.system(size: 24, weight: isSelected ? .bold : .regular))

                Text("Create")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.82))
            }
            .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.82))
            .frame(width: 50, height: 44)
        }
    }
}

private extension Color {
    static let storyInk = Color(red: 0.08, green: 0.07, blue: 0.22)
    static let storyGray = Color(red: 0.39, green: 0.39, blue: 0.46)
    static let storyPurple = Color(red: 0.39, green: 0.18, blue: 0.56)
    static let storyLavender = Color(red: 0.91, green: 0.86, blue: 0.98)
    static let storyRose = Color(red: 0.93, green: 0.73, blue: 0.70)
    static let storyBlush = Color(red: 0.99, green: 0.95, blue: 0.92)
    static let storyCream = Color(red: 1.0, green: 0.98, blue: 0.94)
    static let storySoftPink = Color(red: 0.96, green: 0.90, blue: 0.89)
    static let storyPeach = Color(red: 0.93, green: 0.63, blue: 0.45)
    static let storyGold = Color(red: 0.95, green: 0.69, blue: 0.34)
    static let storyBorder = Color(red: 0.88, green: 0.80, blue: 0.78)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

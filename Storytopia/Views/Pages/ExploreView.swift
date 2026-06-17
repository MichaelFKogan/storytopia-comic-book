import SwiftUI

struct ExploreView: View {
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

            BottomNavigationBar(selectedPage: $selectedPage)
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
}

struct ExploreStory: Identifiable {
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

struct ExploreStoryCard: View {
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

struct ExploreThumbnail: View {
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

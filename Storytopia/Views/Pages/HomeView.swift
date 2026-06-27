import SwiftUI

struct HomeView: View {
    @Binding var selectedPage: StoryPage

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.homePageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    heroCard
                    storyboardsSection
                    socialFeedSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 92)
            }

            BottomNavigationBar(selectedPage: $selectedPage)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Storytopia")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Text("Your life, told in storyboards.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.homeMutedText)
            }

            Spacer()

            HStack(spacing: 10) {
                HeaderIconButton(systemName: "bell")
                HeaderIconButton(systemName: "person.fill")
            }
            .padding(.top, 5)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Create your\nfirst story")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .lineSpacing(2)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Write about your day \nand turn it into a story.")
                .font(.system(size: 14, weight: .medium))
                .lineSpacing(2)
                .foregroundStyle(.white.opacity(0.92))

            Button {
                selectedPage = .create
            } label: {
                Label("New Story", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.homeAccent)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
        .background {
            Image("homepage_banner")
                .resizable()
                .scaledToFill()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.66), .black.opacity(0.22), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 14, y: 6)
    }

    private var socialFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Recent moments", action: "View all")

            LazyVStack(spacing: 14) {
                ForEach(Array(homeFeedEntries.enumerated()), id: \.offset) { index, entry in
                    HomeSocialFeedCard(
                        entry: entry,
                        accentColor: Color.homeAccent,
                        username: homeFeedUsername(for: index),
                        dateText: homeFeedDateText(for: index)
                    )
                }
            }
        }
    }

    private var homeFeedEntries: [PrototypeEntry] {
        [
            PrototypeEntry(
                weekday: "TUE",
                day: "16",
                title: "A slow morning in Williamsburg",
                body: "Coffee, a window seat, and nowhere I needed to be for an hour.",
                time: "9:12 AM",
                location: "Brooklyn, NY",
                imageNames: ["storyboard1", "storyboard2", "storyboard3"]
            ),
            PrototypeEntry(
                weekday: "SUN",
                day: "14",
                title: "Sunday dinner",
                body: "We stayed at the table long after dessert and retold the same family stories.",
                time: "8:04 PM",
                location: "Home",
                imageNames: ["storyboard4", "storyboard5"]
            )
        ]
    }

    private func homeFeedDateText(for index: Int) -> String {
        switch index {
        case 0:
            return "Tue, Jun 16"
        default:
            return "Sun, Jun 14"
        }
    }

    private func homeFeedUsername(for index: Int) -> String {
        switch index {
        case 0:
            return "mikekogan"
        default:
            return "storytopia"
        }
    }

    private var storyboardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Your storyboards", action: "View all")

            VStack(spacing: 3) {
                Text("You haven’t created any storyboards yet.")
                Text("Start by writing your first entry.")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.homeMutedText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.homeBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
    }
}

private struct HomeSocialFeedCard: View {
    let entry: PrototypeEntry
    let accentColor: Color
    let username: String
    let dateText: String

    private var primaryImageName: String? {
        entry.imageNames.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            feedHeader
            feedImage
            feedCaption
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.homeBorder.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: Color.storyInk.opacity(0.08), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
    }

    private var feedHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.9), Color.storyRose.opacity(0.86), Color.storyGold.opacity(0.84)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)

                Circle()
                    .fill(Color.homeCardGray)
                    .frame(width: 28, height: 28)

                Image(systemName: "person.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)
            }
            .frame(width: 38, height: 38)
            .accessibilityLabel("Profile photo placeholder")

            VStack(alignment: .leading, spacing: 2) {
                Text(username)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(dateText)
                    Text("•")
                    Text(entry.time)
                    if let location = entry.location {
                        Text("•")
                        Text(location)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.homeMutedText)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.storyInk.opacity(0.58))
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var feedImage: some View {
        if let primaryImageName {
            Image(primaryImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 326)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    if entry.imageNames.count > 1 {
                        Text("1/\(entry.imageNames.count)")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .frame(height: 24)
                            .background(Color.black.opacity(0.48), in: Capsule())
                            .padding(10)
                    }
                }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(accentColor.opacity(0.56))

                Text(entry.body)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .lineSpacing(3)
                    .foregroundStyle(Color.storyInk)
                    .lineLimit(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 282)
            .padding(22)
            .background(Color.homeCardGray)
        }
    }

    private var feedCaption: some View {
        VStack(alignment: .leading, spacing: 7) {
            (
                Text(entry.title)
                    .fontWeight(.heavy)
                + Text(" \(entry.body)")
            )
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.storyInk.opacity(0.86))
            .lineSpacing(2)
            .lineLimit(3)

            if entry.imageNames.count > 1 {
                HStack(spacing: 5) {
                    ForEach(entry.imageNames.indices, id: \.self) { index in
                        Circle()
                            .fill(index == 0 ? accentColor : Color.homeBorder)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 13)
    }
}

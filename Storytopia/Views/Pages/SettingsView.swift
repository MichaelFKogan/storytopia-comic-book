import SwiftUI

struct SettingsView: View {
    @Binding var selectedPage: StoryPage
    @Environment(\.dismiss) private var dismiss

    @State private var selectedArtStyle = "Anime"

    private let artStyles = ["Anime", "Graphic Novel", "Pixel Art", "Manga", "Cozy Storybook", "Pop Art", "Colored Journal"]

    var body: some View {
        List {
            Section("Account") {
                SettingsRow(
                    systemName: "person.circle",
                    title: "Profile",
                    subtitle: "View your storyboard collection"
                ) {
                    dismiss()
                }
            }

            Section("Journal") {
                SettingsNavigationRow(
                    systemName: "calendar",
                    title: "Daily",
                    subtitle: "Open your daily journal",
                    accessibilityLabel: "Open daily journal"
                ) {
                    DaybookView(
                        selectedPage: $selectedPage,
                        embedsInNavigationStack: false,
                        showsBottomNavigation: false
                    )
                    .enableInteractivePopGesture()
                }
            }

            Section("Create") {
                SettingsNavigationRow(
                    systemName: "paintpalette",
                    title: "Choose Art Style",
                    subtitle: "Preview and pick a storyboard look",
                    accessibilityLabel: "Open choose art style"
                ) {
                    ArtStyleGridSheet(
                        artStyles: artStyles,
                        selectedArtStyle: $selectedArtStyle
                    )
                    .enableInteractivePopGesture()
                }
            }

            Section("More Pages") {
                SettingsNavigationRow(
                    systemName: "safari",
                    title: "Explore",
                    subtitle: "Open the explore feed",
                    accessibilityLabel: "Open explore"
                ) {
                    ExploreView(
                        selectedPage: $selectedPage,
                        showsBottomNavigation: false
                    )
                    .enableInteractivePopGesture()
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.homePageBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .preferredColorScheme(.light)
        .enableInteractivePopGesture()
    }
}

private struct SettingsNavigationRow<Destination: View>: View {
    let systemName: String
    let title: String
    let subtitle: String
    let accessibilityLabel: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            SettingsRowContent(
                systemName: systemName,
                title: title,
                subtitle: subtitle,
                showsChevron: false
            )
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct SettingsRow: View {
    let systemName: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowContent(
                systemName: systemName,
                title: title,
                subtitle: subtitle
            )
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsRowContent: View {
    let systemName: String
    let title: String
    let subtitle: String
    var showsChevron = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.homeAccent)
                .frame(width: 38, height: 38)
                .background(Color.homeAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.storyInk)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.homeMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 8)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .contentShape(Rectangle())
    }
}

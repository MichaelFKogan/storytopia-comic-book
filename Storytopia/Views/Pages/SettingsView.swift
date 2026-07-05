import SwiftUI

struct SettingsView: View {
    @Binding var selectedPage: StoryPage
    @Environment(\.dismiss) private var dismiss

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
                NavigationLink {
                    DaybookView(
                        selectedPage: $selectedPage,
                        embedsInNavigationStack: false,
                        showsBottomNavigation: false
                    )
                    .enableInteractivePopGesture()
                } label: {
                    SettingsRowContent(
                        systemName: "calendar",
                        title: "Daily",
                        subtitle: "Open your daily journal"
                    )
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open daily journal")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.homePageBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .enableInteractivePopGesture()
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

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .contentShape(Rectangle())
    }
}

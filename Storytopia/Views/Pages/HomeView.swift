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
                    captureCard
                    storyboardsSection
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

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capture this moment")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.storyInk)

                    Text("No labels needed. AI will understand.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Text("What’s on your mind?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.homeMutedText)

                Spacer()

                Image(systemName: "mic")
                Image(systemName: "photo")
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(Color.storyInk)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(Color.homeInputGray, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.homeBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
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

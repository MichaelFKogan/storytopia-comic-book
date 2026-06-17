import SwiftUI

struct ProfileView: View {
    @Binding var selectedPage: StoryPage
    let generatedStoryboards: [GeneratedStoryboard]

    @State private var selectedStoryboard: GeneratedStoryboard?

    private let storyboardColumns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.white, .white, Color.storyBlush.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    profileSummary
                    storyboardsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 96)
            }

            BottomNavigationBar(selectedPage: $selectedPage)
        }
        .fullScreenCover(item: $selectedStoryboard) { storyboard in
            StoryboardImageViewer(storyboard: storyboard)
                .presentationBackground(.clear)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Profile")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Spacer()

            CircleIconButton(systemName: "gearshape")
        }
        .padding(.top, 2)
    }

    private var profileSummary: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                ProfilePlaceholder(size: 82)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Story Seeker")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Color.storyInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("@story.seeker")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.storyInk.opacity(0.7))

                    Text("Collecting life's moments,\none storyboard at a time.")
                        .font(.system(size: 14, weight: .medium))
                        .lineSpacing(2)
                        .foregroundStyle(Color.storyInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                ProfileStat(value: "\(generatedStoryboards.count)", title: "Storyboards")
                ProfileStat(value: "\(thisMonthStoryboardCount)", title: "This Month")
                ProfileStat(value: "0", title: "Day Streak")
                ProfileStat(value: "0", title: "Favorites")
            }
        }
        .padding(.top, 2)
    }

    private var thisMonthStoryboardCount: Int {
        let calendar = Calendar.current
        guard let month = calendar.dateInterval(of: .month, for: Date()) else {
            return 0
        }

        return generatedStoryboards.filter { month.contains($0.createdAt) }.count
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

            if generatedStoryboards.isEmpty {
                LazyVGrid(columns: storyboardColumns, spacing: 1) {
                    ForEach(0..<9, id: \.self) { _ in
                        StoryboardPlaceholderCard()
                    }
                }
            } else {
                LazyVGrid(columns: storyboardColumns, spacing: 1) {
                    ForEach(generatedStoryboards) { storyboard in
                        Button {
                            selectedStoryboard = storyboard
                        } label: {
                            GeneratedStoryboardThumbnail(storyboard: storyboard)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct ProfileStat: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.storyInk)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.storyInk.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StoryboardPlaceholderCard: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.38))
                .overlay(
                    Rectangle()
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
        .aspectRatio(0.72, contentMode: .fit)
    }
}

struct GeneratedStoryboardThumbnail: View {
    let storyboard: GeneratedStoryboard

    var body: some View {
        GeometryReader { proxy in
            Image(uiImage: storyboard.image)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
        .clipped()
        .contentShape(Rectangle())
    }
}

struct StoryboardImageViewer: View {
    let storyboard: GeneratedStoryboard

    @Environment(\.dismiss) private var dismiss
    @State private var imageScale: CGFloat = 1
    @State private var lastImageScale: CGFloat = 1
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero

    private let minimumScale: CGFloat = 1
    private let maximumScale: CGFloat = 5
    private let horizontalPadding: CGFloat = 0
    private let verticalPadding: CGFloat = 52

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let viewportSize = proxy.size
                let imageSize = fittedImageSize(in: viewportSize)

                Image(uiImage: storyboard.image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(imageScale * dismissalScale)
                    .offset(imageOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .contentShape(Rectangle())
                    .gesture(imageGesture(imageSize: imageSize, viewportSize: viewportSize))
                    .onTapGesture(count: 2) {
                        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.86)) {
                            if imageScale > minimumScale {
                                resetZoom()
                            } else {
                                imageScale = 2.35
                                lastImageScale = imageScale
                            }

                            imageOffset = boundedOffset(
                                imageOffset,
                                imageSize: imageSize,
                                viewportSize: viewportSize
                            )
                            lastImageOffset = imageOffset
                        }
                    }
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.18), in: Circle())
            }
            .buttonStyle(.plain)
            .opacity(closeButtonOpacity)
            .padding(.top, 18)
            .padding(.trailing, 18)
        }
        .background(Color.clear)
    }

    private func imageGesture(imageSize: CGSize, viewportSize: CGSize) -> some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    imageScale = rubberBandScale(lastImageScale * value)
                    imageOffset = boundedOffset(
                        imageOffset,
                        imageSize: imageSize,
                        viewportSize: viewportSize,
                        allowsResistance: true
                    )
                }
                .onEnded { _ in
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.84)) {
                        imageScale = clampedScale(imageScale)
                        imageOffset = boundedOffset(
                            imageOffset,
                            imageSize: imageSize,
                            viewportSize: viewportSize
                        )

                        if imageScale <= minimumScale {
                            imageOffset = .zero
                        }

                        lastImageScale = imageScale
                        lastImageOffset = imageOffset
                    }
                },
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    if imageScale <= minimumScale {
                        imageOffset = CGSize(
                            width: value.translation.width * 0.16,
                            height: max(value.translation.height, 0)
                        )
                        return
                    }

                    let proposedOffset = CGSize(
                        width: lastImageOffset.width + value.translation.width,
                        height: lastImageOffset.height + value.translation.height
                    )

                    imageOffset = boundedOffset(
                        proposedOffset,
                        imageSize: imageSize,
                        viewportSize: viewportSize,
                        allowsResistance: true
                    )
                }
                .onEnded { value in
                    if imageScale <= minimumScale {
                        closeOrResetAfterSwipe(value)
                        return
                    }

                    let projectedOffset = CGSize(
                        width: imageOffset.width + (value.predictedEndTranslation.width - value.translation.width) * 0.28,
                        height: imageOffset.height + (value.predictedEndTranslation.height - value.translation.height) * 0.28
                    )

                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.86)) {
                        imageOffset = boundedOffset(
                            projectedOffset,
                            imageSize: imageSize,
                            viewportSize: viewportSize
                        )
                        lastImageOffset = imageOffset
                    }
                }
        )
    }

    private func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, minimumScale), maximumScale)
    }

    private func rubberBandScale(_ scale: CGFloat) -> CGFloat {
        if scale < minimumScale {
            return minimumScale - ((minimumScale - scale) * 0.42)
        }

        if scale > maximumScale {
            return maximumScale + ((scale - maximumScale) * 0.18)
        }

        return scale
    }

    private func fittedImageSize(in viewportSize: CGSize) -> CGSize {
        let availableSize = CGSize(
            width: max(viewportSize.width - (horizontalPadding * 2), 1),
            height: max(viewportSize.height - (verticalPadding * 2), 1)
        )
        let sourceSize = storyboard.image.size
        let sourceAspectRatio = sourceSize.width / max(sourceSize.height, 1)
        let availableAspectRatio = availableSize.width / max(availableSize.height, 1)

        if sourceAspectRatio > availableAspectRatio {
            let height = availableSize.width / sourceAspectRatio
            return CGSize(width: availableSize.width, height: height)
        } else {
            let width = availableSize.height * sourceAspectRatio
            return CGSize(width: width, height: availableSize.height)
        }
    }

    private func boundedOffset(
        _ offset: CGSize,
        imageSize: CGSize,
        viewportSize: CGSize,
        allowsResistance: Bool = false
    ) -> CGSize {
        let bounds = offsetBounds(imageSize: imageSize, viewportSize: viewportSize)

        return CGSize(
            width: boundedValue(offset.width, limit: bounds.width, allowsResistance: allowsResistance),
            height: boundedValue(offset.height, limit: bounds.height, allowsResistance: allowsResistance)
        )
    }

    private func offsetBounds(imageSize: CGSize, viewportSize: CGSize) -> CGSize {
        let visibleSize = CGSize(
            width: max(viewportSize.width - (horizontalPadding * 2), 1),
            height: max(viewportSize.height - (verticalPadding * 2), 1)
        )

        return CGSize(
            width: max(((imageSize.width * imageScale) - visibleSize.width) / 2, 0),
            height: max(((imageSize.height * imageScale) - visibleSize.height) / 2, 0)
        )
    }

    private func boundedValue(_ value: CGFloat, limit: CGFloat, allowsResistance: Bool) -> CGFloat {
        guard limit > 0 else {
            return allowsResistance ? value * 0.18 : 0
        }

        guard abs(value) > limit else {
            return value
        }

        let overshoot = abs(value) - limit
        let resistedOvershoot = allowsResistance ? rubberBandDistance(overshoot) : 0
        return (limit + resistedOvershoot) * (value < 0 ? -1 : 1)
    }

    private func rubberBandDistance(_ distance: CGFloat) -> CGFloat {
        (1 - (1 / ((distance * 0.008) + 1))) * 120
    }

    private var backgroundOpacity: Double {
        guard imageScale <= minimumScale else {
            return 1
        }

        return 1 - (Double(dismissProgress) * 0.92)
    }

    private var dismissProgress: CGFloat {
        min(max(imageOffset.height / 260, 0), 1)
    }

    private var dismissalScale: CGFloat {
        guard imageScale <= minimumScale else {
            return 1
        }

        return 1 - (dismissProgress * 0.12)
    }

    private var closeButtonOpacity: Double {
        guard imageScale <= minimumScale else {
            return 1
        }

        return max(1 - Double(dismissProgress * 1.7), 0)
    }

    private func closeOrResetAfterSwipe(_ value: DragGesture.Value) {
        let isDownwardSwipe = value.translation.height > 120
        let isMostlyVertical = value.translation.height > abs(value.translation.width)

        if isDownwardSwipe && isMostlyVertical {
            dismiss()
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            imageOffset = .zero
            lastImageOffset = .zero
        }
    }

    private func resetOffsetIfNeeded() {
        guard imageScale <= minimumScale else {
            return
        }

        imageOffset = .zero
        lastImageOffset = .zero
    }

    private func resetZoom() {
        imageScale = minimumScale
        lastImageScale = minimumScale
        imageOffset = .zero
        lastImageOffset = .zero
    }
}

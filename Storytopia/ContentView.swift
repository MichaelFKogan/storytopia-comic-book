//
//  ContentView.swift
//  Storytopia
//
//  Created by Mike Kogan on 5/28/26.
//

import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedPage: StoryPage = .home
    @State private var entryText = ""
    @State private var generatedStoryboards: [GeneratedStoryboard] = GeneratedStoryboardStore.load()

    var body: some View {
        ZStack {
            currentPage
        }
    }

    @ViewBuilder
    private var currentPage: some View {
        switch selectedPage {
        case .home:
            homePage
                .transition(.identity)
                .zIndex(0)
        case .explore:
            ExploreView(selectedPage: $selectedPage)
                .transition(.identity)
                .zIndex(0)
        case .create:
            CreateEntryView(
                entryText: $entryText,
                selectedPage: $selectedPage,
                generatedStoryboards: $generatedStoryboards
            )
            .transition(.move(edge: .trailing))
            .zIndex(1)
        case .journal:
            JournalView(selectedPage: $selectedPage)
                .transition(.identity)
                .zIndex(0)
        case .profile:
            ProfileView(
                selectedPage: $selectedPage,
                generatedStoryboards: generatedStoryboards
            )
            .transition(.identity)
            .zIndex(0)
        }
    }

    private var homePage: some View {
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

private enum StoryPage {
    case home
    case explore
    case create
    case journal
    case profile
}

private enum StoryboardLayoutOption: String, CaseIterable, Identifiable {
    case twoRectangles
    case threeHorizontalPanels
    case threePanels
    case threeVerticalPanels
    case fourSquares
    case fourVerticalPanels
    case fourHorizontalRectangles
    case fiveHorizontalPanels
    case fiveClassic
    case sixSquares

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .twoRectangles:
            return "2 Rectangles"
        case .threeHorizontalPanels:
            return "3 Horiz."
        case .threePanels:
            return "3 Panels"
        case .threeVerticalPanels:
            return "3 Vertical"
        case .fourSquares:
            return "4 Squares"
        case .fourVerticalPanels:
            return "4 Vertical"
        case .fourHorizontalRectangles:
            return "4 Horiz."
        case .fiveHorizontalPanels:
            return "5 Horiz."
        case .fiveClassic:
            return "5 Classic"
        case .sixSquares:
            return "6 Squares"
        }
    }

    var panelCount: Int {
        switch self {
        case .twoRectangles:
            return 2
        case .threeHorizontalPanels, .threePanels, .threeVerticalPanels:
            return 3
        case .fourSquares, .fourVerticalPanels, .fourHorizontalRectangles:
            return 4
        case .fiveHorizontalPanels, .fiveClassic:
            return 5
        case .sixSquares:
            return 6
        }
    }

    var promptDescription: String {
        switch self {
        case .twoRectangles:
            return "two full-width horizontal rectangle panels stacked evenly from top to bottom."
        case .threeHorizontalPanels:
            return "three full-width horizontal rectangle panels stacked evenly from top to bottom."
        case .threePanels:
            return "one large full-width horizontal rectangle panel on top, with two equal rectangle panels side by side underneath."
        case .threeVerticalPanels:
            return "three equal tall vertical rectangle panels side by side in a single row."
        case .fourSquares:
            return "four equal square panels in a clean 2 by 2 grid."
        case .fourVerticalPanels:
            return "four equal tall vertical rectangle panels side by side in a single row."
        case .fourHorizontalRectangles:
            return "four full-width horizontal rectangle panels stacked evenly from top to bottom."
        case .fiveHorizontalPanels:
            return "five full-width horizontal rectangle panels stacked evenly from top to bottom."
        case .fiveClassic:
            return "row 1 has two equal panels side by side; row 2 has one wide full-width panel; row 3 has two equal panels side by side."
        case .sixSquares:
            return "six equal square panels in a clean 2-column by 3-row grid."
        }
    }

    static func random(for imageCount: Int) -> StoryboardLayoutOption {
        let panelCount = storyboardPanelCount(for: imageCount)
        let matchingLayouts = allCases.filter { $0.panelCount == panelCount }
        return matchingLayouts.randomElement() ?? .fourSquares
    }
}

private struct GeneratedStoryboard: Identifiable {
    let id: UUID
    let image: UIImage
    let promptText: String
    let artStyle: String
    let sourcePhotoCount: Int
    let createdAt: Date
    let imageFileName: String?

    init(
        id: UUID = UUID(),
        image: UIImage,
        promptText: String,
        artStyle: String,
        sourcePhotoCount: Int,
        createdAt: Date = Date(),
        imageFileName: String? = nil
    ) {
        self.id = id
        self.image = image
        self.promptText = promptText
        self.artStyle = artStyle
        self.sourcePhotoCount = sourcePhotoCount
        self.createdAt = createdAt
        self.imageFileName = imageFileName
    }
}

private enum OpenAITestConfig {
    // Temporary test-only client key. Remove this before pushing or shipping.
    static let apiKey = ""
    static let imageModel = "gpt-image-2"
}

private enum GeneratedStoryboardStore {
    private static let metadataKey = "StorytopiaGeneratedStoryboardMetadata"

    static func load() -> [GeneratedStoryboard] {
        guard
            let metadataData = UserDefaults.standard.data(forKey: metadataKey),
            let metadata = try? JSONDecoder().decode([GeneratedStoryboardMetadata].self, from: metadataData)
        else {
            return []
        }

        return metadata.compactMap { item in
            let imageURL = imagesDirectory.appendingPathComponent(item.imageFileName)
            guard
                let imageData = try? Data(contentsOf: imageURL),
                let image = UIImage(data: imageData)
            else {
                return nil
            }

            return GeneratedStoryboard(
                id: item.id,
                image: image,
                promptText: item.promptText,
                artStyle: item.artStyle,
                sourcePhotoCount: item.sourcePhotoCount,
                createdAt: item.createdAt,
                imageFileName: item.imageFileName
            )
        }
    }

    static func save(_ storyboards: [GeneratedStoryboard]) {
        let metadata = storyboards.compactMap { storyboard -> GeneratedStoryboardMetadata? in
            guard let imageFileName = storyboard.imageFileName else {
                return nil
            }

            return GeneratedStoryboardMetadata(
                id: storyboard.id,
                promptText: storyboard.promptText,
                artStyle: storyboard.artStyle,
                sourcePhotoCount: storyboard.sourcePhotoCount,
                createdAt: storyboard.createdAt,
                imageFileName: imageFileName
            )
        }

        guard let metadataData = try? JSONEncoder().encode(metadata) else {
            return
        }

        UserDefaults.standard.set(metadataData, forKey: metadataKey)
    }

    static func persistedStoryboard(
        image: UIImage,
        promptText: String,
        artStyle: String,
        sourcePhotoCount: Int
    ) throws -> GeneratedStoryboard {
        try FileManager.default.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )

        let id = UUID()
        let imageFileName = "\(id.uuidString).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(imageFileName)

        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw StoryboardGenerationError.invalidRequest
        }

        try imageData.write(to: imageURL, options: [.atomic])

        return GeneratedStoryboard(
            id: id,
            image: image,
            promptText: promptText,
            artStyle: artStyle,
            sourcePhotoCount: sourcePhotoCount,
            imageFileName: imageFileName
        )
    }

    private static var imagesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GeneratedStoryboards", isDirectory: true)
    }
}

private struct GeneratedStoryboardMetadata: Codable {
    let id: UUID
    let promptText: String
    let artStyle: String
    let sourcePhotoCount: Int
    let createdAt: Date
    let imageFileName: String
}

private enum StoryboardGenerationError: LocalizedError {
    case missingAPIKey
    case missingImages
    case invalidRequest
    case invalidResponse
    case noGeneratedImage
    case openAIMessage(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an OpenAI API key before generating a storyboard."
        case .missingImages:
            return "Add at least one photo before generating a storyboard."
        case .invalidRequest:
            return "The storyboard request could not be prepared."
        case .invalidResponse:
            return "OpenAI returned a response Storytopia could not read."
        case .noGeneratedImage:
            return "OpenAI did not return a storyboard image."
        case .openAIMessage(let message):
            return message
        }
    }
}

private struct OpenAIImageGenerationService {
    private let endpoint = URL(string: "https://api.openai.com/v1/images/edits")!
    private let requestTimeout: TimeInterval = 600

    func generateStoryboard(
        apiKey: String,
        text: String,
        artStyle: String,
        layout: StoryboardLayoutOption,
        images: [UIImage]
    ) async throws -> UIImage {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StoryboardGenerationError.missingAPIKey
        }

        guard !images.isEmpty else {
            throw StoryboardGenerationError.missingImages
        }

        let prompt = makePrompt(text: text, artStyle: artStyle, layout: layout, imageCount: images.count)
        var request = URLRequest(url: endpoint)
        let boundary = "Boundary-\(UUID().uuidString)"
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.appendMultipartField(name: "model", value: OpenAITestConfig.imageModel, boundary: boundary)
        body.appendMultipartField(name: "prompt", value: prompt, boundary: boundary)
        body.appendMultipartField(name: "size", value: "1024x1536", boundary: boundary)
        body.appendMultipartField(name: "quality", value: "medium", boundary: boundary)

        for (index, image) in images.prefix(6).enumerated() {
            guard let imageData = image.storytopiaPreparedJPEGData(maxDimension: 1536, compressionQuality: 0.76) else {
                throw StoryboardGenerationError.invalidRequest
            }

            body.appendMultipartFile(
                name: "image[]",
                fileName: "storyboard-reference-\(index + 1).jpg",
                mimeType: "image/jpeg",
                data: imageData,
                boundary: boundary
            )
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = requestTimeout
        let session = URLSession(configuration: configuration)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoryboardGenerationError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw StoryboardGenerationError.openAIMessage(errorResponse.error.message)
            }

            throw StoryboardGenerationError.openAIMessage("OpenAI returned status \(httpResponse.statusCode).")
        }

        let decoded = try JSONDecoder().decode(OpenAIImageResponse.self, from: data)
        guard
            let base64Image = decoded.data.first?.b64JSON,
            let imageData = Data(base64Encoded: base64Image),
            let image = UIImage(data: imageData)
        else {
            throw StoryboardGenerationError.noGeneratedImage
        }

        return image
    }

    private func makePrompt(
        text: String,
        artStyle: String,
        layout: StoryboardLayoutOption,
        imageCount: Int
    ) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let storyText = trimmedText.isEmpty ? "No written story was provided. Infer a warm, visually coherent story about the moment from the uploaded photos." : trimmedText
        let referencePhotoCount = min(imageCount, 6)

        return """
        Create a vertical illustrated comic/storyboard about the moment using the user's \(referencePhotoCount) uploaded reference photo(s) and optional written story.

        USER STORY:
        \(storyText)

        ART STYLE:
        \(artStyle)

        STYLE PRIORITY — this is the most important instruction:
        \(artStylePromptDescription(for: artStyle))

        The final image must fully commit to the selected art style.
        Preserve the identity of people, pets, locations, clothing, and important objects from the reference photos, but DO NOT preserve photographic realism.
        Strongly reinterpret everything in the selected style.
        The result should look like authentic \(artStyle) artwork, not a photograph with an art filter applied.
        When there is a conflict between realism and the selected art style, always prioritize the selected art style.

        FORMAT:
        - Output ONE single tall image divided into exactly \(layout.panelCount) distinct comic panels with visible gutters or borders.
        - Panel layout (top to bottom): \(layout.promptDescription)
        - Create a coherent beginning, middle, and end.
        - Show a progression of events rather than repeating the same scene.
        - Generate a true illustrated comic/storyboard.
        - Never create a photo collage, contact sheet, photomontage, or collection of separate photos.
        - Fully redraw every scene as original illustrated artwork.

        REFERENCE PHOTOS:
        - Use ALL uploaded reference photos.
        - Do not ignore uploaded photos.
        - Use them as references for identity, pets, clothing, objects, locations, mood, and story details.
        - Do NOT map photo 1 to panel 1, photo 2 to panel 2, and so on.
        - You may combine details from multiple photos when it improves storytelling.
        - Keep characters and important visual elements recognizable and consistent across panels.
        - Reimagine every scene in the selected art style rather than recreating the original photographs.

        TEXT:
        - Minimal text.
        - Minimal speech bubbles.
        - Minimal captions.
        - Prioritize visual storytelling.
        """
    }
}

private func storyboardPanelCount(for imageCount: Int) -> Int {
    switch imageCount {
    case ...0:
        return 0
    case 1...3:
        return 3
    case 4:
        return 4
    case 5:
        return 5
    default:
        return 6
    }
}

private struct OpenAIImageResponse: Decodable {
    struct ImageData: Decodable {
        let b64JSON: String?

        private enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
        }
    }

    let data: [ImageData]
}

private struct OpenAIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
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

            BottomNavigationBar(selectedPage: $selectedPage)
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

private struct ProfileStat: View {
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

private struct StoryboardPlaceholderCard: View {
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

private struct GeneratedStoryboardThumbnail: View {
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

private struct StoryboardImageViewer: View {
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

private struct CreateEntryView: View {
    private let artStyles = ["Anime", "Graphic Novel", "Pixel Art", "Manga", "Cozy Storybook", "Pop Art", "Colored Journal"]

    @Binding var entryText: String
    @Binding var selectedPage: StoryPage
    @Binding var generatedStoryboards: [GeneratedStoryboard]

    @State private var selectedArtStyle = "Anime"
    @State private var previewLayout = StoryboardLayoutOption.fourSquares
    @State private var storyboardPhotos: [UIImage?] = Array(repeating: nil, count: 6)
    @State private var selectedPhotoSlot: Int?
    @State private var isShowingPhotoSourceDialog = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingCamera = false
    @State private var isShowingDraftSavedConfirmation = false
    @State private var isGeneratingStoryboard = false
    @State private var generationErrorMessage: String?
    @State private var isShowingExpandedEditor = false
    @State private var isShowingArtStyleGrid = false
    @State private var isShowingClearTextConfirmation = false
    @State private var storyTitle = ""
    @State private var storyLocation = ""
    @State private var storyDate = Date()
    @State private var savesDraft = true
    @State private var isPrivateEntry = false
    @State private var selectedPhotoPickerItems: [PhotosPickerItem] = []
    @State private var draggedStoryboardPhotoIndex: Int?
    @FocusState private var isEditorFocused: Bool

    private func dismissKeyboard() {
        isEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        ZStack {
            Color.homePageBackground
                .ignoresSafeArea()
                .onTapGesture {
                    dismissKeyboard()
                }

            layoutPage
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraPhotoPicker { image in
                setStoryboardPhoto(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingExpandedEditor) {
            ExpandedEntryEditor(entryText: $entryText)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingArtStyleGrid) {
            ArtStyleGridSheet(
                artStyles: artStyles,
                selectedArtStyle: $selectedArtStyle
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .photosPicker(
            isPresented: $isShowingPhotoLibrary,
            selection: $selectedPhotoPickerItems,
            maxSelectionCount: nil,
            selectionBehavior: .ordered,
            matching: .images
        )
        .confirmationDialog(
            "Add Photo",
            isPresented: $isShowingPhotoSourceDialog,
            titleVisibility: .visible
        ) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    selectedPhotoSlot = nextAvailablePhotoSlot
                    isShowingCamera = true
                }
            }

            Button("Photo Library") {
                selectedPhotoSlot = nextAvailablePhotoSlot
                isShowingPhotoLibrary = true
            }

            Button("Cancel", role: .cancel) {
            }
        }
        .alert("Draft saved", isPresented: $isShowingDraftSavedConfirmation) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text("You can keep editing this entry whenever you're ready.")
        }
        .alert(
            "Storyboard generation failed",
            isPresented: Binding(
                get: { generationErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        generationErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(generationErrorMessage ?? "")
        }
        .alert("Clear writing?", isPresented: $isShowingClearTextConfirmation) {
            Button("Clear", role: .destructive) {
                entryText = ""
                dismissKeyboard()
            }

            Button("Cancel", role: .cancel) {
            }
        } message: {
            Text("Are you sure? This will remove everything you've written in this entry.")
        }
        .onChange(of: selectedPhotoPickerItems) { items in
            guard !items.isEmpty else {
                return
            }

            Task {
                await loadPhotoLibraryImages(from: items)
            }
        }
    }

    private func startStoryboardGeneration() {
        guard !isGeneratingStoryboard else {
            return
        }

        let apiKey = OpenAITestConfig.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty, apiKey != "PASTE_OPENAI_API_KEY_HERE" else {
            generationErrorMessage = StoryboardGenerationError.missingAPIKey.localizedDescription
            return
        }

        let photos = storyboardPhotos.compactMap { $0 }
        guard !photos.isEmpty else {
            generationErrorMessage = StoryboardGenerationError.missingImages.localizedDescription
            return
        }

        let layout = StoryboardLayoutOption.random(for: photos.count)
        isGeneratingStoryboard = true

        Task {
            do {
                let image = try await OpenAIImageGenerationService().generateStoryboard(
                    apiKey: apiKey,
                    text: entryText,
                    artStyle: selectedArtStyle,
                    layout: layout,
                    images: photos
                )

                let storyboard = try GeneratedStoryboardStore.persistedStoryboard(
                    image: image,
                    promptText: entryText,
                    artStyle: selectedArtStyle,
                    sourcePhotoCount: photos.count
                )

                await MainActor.run {
                    generatedStoryboards.insert(storyboard, at: 0)
                    GeneratedStoryboardStore.save(generatedStoryboards)
                    isGeneratingStoryboard = false
                    selectedPage = .profile
                }
            } catch {
                await MainActor.run {
                    generationErrorMessage = error.localizedDescription
                    isGeneratingStoryboard = false
                }
            }
        }
    }

    private var layoutPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            pageHeader(title: "New Entry")

            ScrollView(showsIndicators: false) {
                createEntryContent
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(pageTapBackground)
        }
        .background(Color.homePageBackground)
    }

    private var pageTapBackground: some View {
        Color.homePageBackground
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
    }

    private func pageHeader(title: String) -> some View {
        HStack(alignment: .center) {
            Button {
                dismissKeyboard()
                withAnimation(.snappy(duration: 0.32)) {
                    selectedPage = .home
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.storyPurple)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.leading, -10)

            Text(title)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color.storyInk)

            Spacer()

            Button {
                dismissKeyboard()
                isShowingDraftSavedConfirmation = true
            } label: {
                Text("Save Draft")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.storyPurple)
                    .frame(height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private var createEntryContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            storyDetailsStepContent
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }

    private var storyDetailsStepContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            editorCard
            photoStripSection
            artStylePickerSection
            storyDetailsCard
            entryPrivacyCard
            generateStoryboardButton
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var photoStripSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Reference Photos")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.storyInk)

                Spacer(minLength: 10)

                Text("Long press to reorder")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.homeMutedText.opacity(storyboardPhotos.compactMap { $0 }.count > 1 ? 1 : 0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(storyboardPhotos.compactMap { $0 }.enumerated()), id: \.offset) { index, image in
                        StoryboardPhotoStripThumbnail(image: image) {
                            removeStoryboardPhoto(at: index)
                        }
                            .onDrag {
                                draggedStoryboardPhotoIndex = index
                                return NSItemProvider(object: String(index) as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: StoryboardPhotoDropDelegate(
                                    photos: $storyboardPhotos,
                                    draggedIndex: $draggedStoryboardPhotoIndex,
                                    destinationIndex: index
                                )
                            )
                    }

                    Button {
                        dismissKeyboard()
                        selectedPhotoSlot = nextAvailablePhotoSlot
                        isShowingPhotoSourceDialog = true
                    } label: {
                        StoryboardPhotoStripAddButton()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add reference photos")
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }

    private func photoSourceButton(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            dismissKeyboard()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(Color.storyPurple)
                    .frame(height: 26)

                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.storyInk.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(width: 76, height: 82)
            .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.storyPurple.opacity(0.32), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var storyboardPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("Storyboard Preview")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.storyInk)

                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.storyGold)
                    }

                    Text("Layout changes each time you generate")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                }

                Spacer(minLength: 8)

                HStack(spacing: 5) {
                    let photoCount = storyboardPhotos.compactMap { $0 }.count
                    Text("\(previewLayout.title) · \(storyboardPanelCount(for: photoCount)) panels")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.storyInk.opacity(0.7))

                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.storyPurple)
                }
            }

            storyboardPreviewLayout(previewLayout)
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }

    @ViewBuilder
    private func storyboardPreviewLayout(_ layout: StoryboardLayoutOption) -> some View {
        switch layout {
        case .twoRectangles:
            VStack(spacing: 8) {
                storyboardPhotoPanel(index: 0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)

                storyboardPhotoPanel(index: 1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
            }
        case .threeHorizontalPanels:
            VStack(spacing: 8) {
                ForEach(0..<layout.panelCount, id: \.self) { index in
                    storyboardPhotoPanel(index: index)
                        .frame(maxWidth: .infinity)
                        .frame(height: 112)
                }
            }
        case .threePanels:
            VStack(spacing: 8) {
                storyboardPhotoPanel(index: 0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 192)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 1)
                    storyboardPhotoPanel(index: 2)
                }
                .frame(height: 148)
            }
        case .threeVerticalPanels:
            HStack(spacing: 8) {
                storyboardPhotoPanel(index: 0)
                storyboardPhotoPanel(index: 1)
                storyboardPhotoPanel(index: 2)
            }
            .frame(height: 340)
        case .fourSquares:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 0)
                    storyboardPhotoPanel(index: 1)
                }
                .frame(height: 170)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 2)
                    storyboardPhotoPanel(index: 3)
                }
                .frame(height: 170)
            }
        case .fourVerticalPanels:
            HStack(spacing: 8) {
                storyboardPhotoPanel(index: 0)
                storyboardPhotoPanel(index: 1)
                storyboardPhotoPanel(index: 2)
                storyboardPhotoPanel(index: 3)
            }
            .frame(height: 340)
        case .fourHorizontalRectangles:
            VStack(spacing: 8) {
                ForEach(0..<layout.panelCount, id: \.self) { index in
                    storyboardPhotoPanel(index: index)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                }
            }
        case .fiveHorizontalPanels:
            VStack(spacing: 8) {
                ForEach(0..<layout.panelCount, id: \.self) { index in
                    storyboardPhotoPanel(index: index)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                }
            }
        case .fiveClassic:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 0)
                    storyboardPhotoPanel(index: 1)
                }
                .frame(height: 132)

                storyboardPhotoPanel(index: 2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 106)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 3)
                    storyboardPhotoPanel(index: 4)
                }
                .frame(height: 108)
            }
        case .sixSquares:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 0)
                    storyboardPhotoPanel(index: 1)
                }
                .aspectRatio(2, contentMode: .fit)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 2)
                    storyboardPhotoPanel(index: 3)
                }
                .aspectRatio(2, contentMode: .fit)

                HStack(spacing: 8) {
                    storyboardPhotoPanel(index: 4)
                    storyboardPhotoPanel(index: 5)
                }
                .aspectRatio(2, contentMode: .fit)
            }
        }
    }

    private func storyboardPhotoPanel(index: Int) -> some View {
        StoryboardPhotoPanel(
            image: storyboardPhotos.indices.contains(index) ? storyboardPhotos[index] : nil,
            placeholderImageName: "storyboard_placeholder_\(min(index + 1, 5))",
            number: index + 1
        )
    }

    private var nextAvailablePhotoSlot: Int? {
        storyboardPhotos.firstIndex(where: { $0 == nil }) ?? storyboardPhotos.indices.last
    }

    private func setStoryboardPhoto(_ image: UIImage) {
        guard let slot = selectedPhotoSlot ?? nextAvailablePhotoSlot else {
            return
        }

        storyboardPhotos[slot] = image
        selectedPhotoSlot = nil
    }

    private func setStoryboardPhotos(_ images: [UIImage]) {
        guard
            !images.isEmpty,
            let firstSlot = selectedPhotoSlot ?? nextAvailablePhotoSlot
        else {
            selectedPhotoSlot = nil
            return
        }

        var updatedPhotos = storyboardPhotos
        var slot = firstSlot

        for image in images {
            guard updatedPhotos.indices.contains(slot) else {
                break
            }

            updatedPhotos[slot] = image
            slot += 1
        }

        storyboardPhotos = updatedPhotos
        selectedPhotoSlot = nil
    }

    @MainActor
    private func loadPhotoLibraryImages(from items: [PhotosPickerItem]) async {
        defer {
            selectedPhotoPickerItems = []
        }

        var images: [UIImage] = []

        for item in items {
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                continue
            }

            images.append(image)
        }

        setStoryboardPhotos(images)
    }

    private func removeStoryboardPhoto(at index: Int) {
        var existingPhotos = storyboardPhotos.compactMap { $0 }
        guard existingPhotos.indices.contains(index) else {
            return
        }

        existingPhotos.remove(at: index)
        storyboardPhotos = paddedStoryboardPhotos(existingPhotos)
    }

    private func paddedStoryboardPhotos(_ photos: [UIImage]) -> [UIImage?] {
        let trimmedPhotos = Array(photos.prefix(storyboardPhotos.count))
        return trimmedPhotos.map(Optional.some) + Array(repeating: nil, count: max(0, storyboardPhotos.count - trimmedPhotos.count))
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.storyPurple.opacity(0.58))

                    Text(storyDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)

                    Circle()
                        .fill(Color.homeMutedText.opacity(0.38))
                        .frame(width: 3, height: 3)

                    Text("New entry")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                }

                Spacer(minLength: 12)

                Button {
                    dismissKeyboard()
                    isShowingClearTextConfirmation = true
                } label: {
                    Text("Edit")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(entryText.isEmpty ? Color.storyGray.opacity(0.42) : Color.storyPurple)
                        .frame(height: 32)
                }
                .buttonStyle(.plain)
                .disabled(entryText.isEmpty)
                .accessibilityLabel("Clear writing")
            }
            .padding(.horizontal, 2)

            ZStack(alignment: .topLeading) {
                journalPaperBackground

                VStack(alignment: .leading, spacing: 14) {
                    Text("What's on your mind?")
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(Color.storyInk.opacity(0.66))

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $entryText)
                            .font(.system(size: 16, weight: .regular))
                            .lineSpacing(7)
                            .foregroundStyle(Color.storyInk.opacity(0.78))
                            .scrollContentBackground(.hidden)
                            .scrollIndicators(.visible, axes: .vertical)
                            .background(Color.clear)
                            .focused($isEditorFocused)
                            .padding(.horizontal, -5)
                            .padding(.vertical, -7)
                            .padding(.bottom, 28)
                            .onTapGesture {
                                isEditorFocused = true
                            }

                        if entryText.isEmpty {
                            Text("Today was...")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.storyGray.opacity(0.46))
                                .padding(.vertical, 1)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.top, 2)
            }
            .frame(height: 252)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    dismissKeyboard()
                    isShowingExpandedEditor = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.storyPurple)
                        .frame(width: 34, height: 34)
                        .background(Color.storyPurple.opacity(0.1), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.storyPurple.opacity(0.26), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Expand writing box")
                .padding(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private var journalPaperBackground: some View {
        Color.clear
            .overlay {
                VStack(spacing: 25) {
                    ForEach(0..<9, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.storyPurple.opacity(0.035))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 69)
            }
    }

    private var storyDetailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Story Details")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.storyInk)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)

            storyTextFieldRow(
                icon: "pencil",
                title: "Title",
                placeholder: "Give your story a title",
                text: $storyTitle
            )

            Divider()
                .padding(.leading, 44)

            storyTextFieldRow(
                icon: "location",
                title: "Location",
                placeholder: "Add a location",
                text: $storyLocation
            )

            Divider()
                .padding(.leading, 44)

            DatePicker(selection: $storyDate, displayedComponents: [.date, .hourAndMinute]) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.storyPurple)
                        .frame(width: 20)

                    Text("Date/time")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.storyInk.opacity(0.9))
                }
            }
            .font(.system(size: 13, weight: .medium))
            .tint(Color.storyPurple)
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

    private func storyTextFieldRow(
        icon: String,
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.storyPurple)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.storyInk.opacity(0.9))
                .frame(width: 72, alignment: .leading)

            TextField(placeholder, text: text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.storyInk)
                .tint(Color.storyPurple)
                .textInputAutocapitalization(.words)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
    }

    private var entryPrivacyCard: some View {
        VStack(spacing: 0) {
            entrySwitchRow(
                icon: "tray.and.arrow.down",
                title: "Save as Draft",
                subtitle: "Save progress and come back later",
                isOn: $savesDraft
            )

            Divider()
                .padding(.leading, 44)

            entrySwitchRow(
                icon: "lock.shield",
                title: "Private Entry",
                subtitle: "Only you can see this entry",
                isOn: $isPrivateEntry
            )
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }

    private func entrySwitchRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.storyPurple)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.storyInk)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.homeMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.storyPurple))
        .padding(.horizontal, 12)
        .frame(height: 58)
    }

    private var artStylePickerSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center) {
                Text("Choose Art Style")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Button {
                    dismissKeyboard()
                    isShowingArtStyleGrid = true
                } label: {
                    Text("View all")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.storyPurple)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(artStyles, id: \.self) { style in
                        Button {
                            selectedArtStyle = style
                            dismissKeyboard()
                        } label: {
                            InlineArtStyleOption(
                                title: style,
                                isSelected: selectedArtStyle == style
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
            }
        }
    }

    private var generateStoryboardButton: some View {
        Button {
            dismissKeyboard()
            startStoryboardGeneration()
        } label: {
            HStack(spacing: 7) {
                if isGeneratingStoryboard {
                    ProgressView()
                        .tint(.white)

                    Text("Generating...")
                } else {
                    Text("Generate Storyboard")
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                }
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
        .disabled(isGeneratingStoryboard)
        .opacity(isGeneratingStoryboard ? 0.76 : 1)
    }
}

private struct ExpandedEntryEditor: View {
    @Binding var entryText: String

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text("Write about this storyboard")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.storyPurple)
                        .frame(height: 38)
                }
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $entryText)
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(5)
                    .foregroundStyle(Color.storyInk.opacity(0.86))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .padding(.horizontal, -5)
                    .padding(.vertical, -7)

                if entryText.isEmpty {
                    Text("Start writing...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.storyGray.opacity(0.46))
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.storyBorder.opacity(0.7), lineWidth: 1)
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .background(Color.homePageBackground)
        .onAppear {
            isFocused = true
        }
    }
}

private struct ArtStyleGridSheet: View {
    let artStyles: [String]

    @Binding var selectedArtStyle: String

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Choose art style")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.storyInk)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.storyPurple)
                        .frame(height: 38)
                }
            }

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(artStyles, id: \.self) { style in
                        Button {
                            selectedArtStyle = style
                        } label: {
                            ArtStyleGridOption(
                                title: style,
                                isSelected: selectedArtStyle == style
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 18)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .background(Color.homePageBackground)
    }
}

private struct ArtStyleGridOption: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 7) {
            GeometryReader { proxy in
                ZStack(alignment: .topTrailing) {
                    Image(artStyleAssetName(for: title))
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.width)
                        .clipped()

                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(isSelected ? Color.storyPurple : Color.storyBorder.opacity(0.5), lineWidth: isSelected ? 2.5 : 1)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white, Color.storyPurple)
                            .padding(7)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .aspectRatio(1, contentMode: .fit)

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private struct StoryboardPhotoStripThumbnail: View {
    let image: UIImage
    let removeAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 82, height: 82)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.storyInk.opacity(0.72), lineWidth: 1)
                )

            Button {
                removeAction()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.black.opacity(0.58), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(3)
            .accessibilityLabel("Remove photo")
        }
        .frame(width: 82, height: 82)
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}

private struct StoryboardPhotoStripAddButton: View {
    var body: some View {
        VStack {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.storyPurple)
        }
        .frame(width: 82, height: 82)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.storyPurple.opacity(0.32), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
        )
        .accessibilityLabel("Add photos")
    }
}

private struct StoryboardPhotoDropDelegate: DropDelegate {
    @Binding var photos: [UIImage?]
    @Binding var draggedIndex: Int?

    let destinationIndex: Int

    func dropEntered(info: DropInfo) {
        guard
            let draggedIndex,
            draggedIndex != destinationIndex
        else {
            return
        }

        var compactPhotos = photos.compactMap { $0 }
        guard
            compactPhotos.indices.contains(draggedIndex),
            compactPhotos.indices.contains(destinationIndex)
        else {
            return
        }

        let photo = compactPhotos.remove(at: draggedIndex)
        compactPhotos.insert(photo, at: destinationIndex)
        photos = compactPhotos.map(Optional.some) + Array(repeating: nil, count: max(0, photos.count - compactPhotos.count))
        self.draggedIndex = destinationIndex
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedIndex = nil
        return true
    }
}

private struct StoryboardPhotoPanel: View {
    let image: UIImage?
    let placeholderImageName: String
    let number: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)

            GeometryReader { proxy in
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                    } else {
                        Image(placeholderImageName)
                            .resizable()
                    }
                }
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }

            if image == nil {
                Rectangle()
                    .fill(Color.white.opacity(0.34))
            }

            Text("\(number)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.storyPurple)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.82), in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.storyPurple.opacity(0.22), lineWidth: 1)
                )
        }
        .overlay(
            Rectangle()
                .stroke(Color.storyInk.opacity(0.88), lineWidth: 1.5)
        )
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

private struct CameraPhotoPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            dismiss: dismiss,
            onImagePicked: onImagePicked
        )
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let dismiss: DismissAction
        private let onImagePicked: (UIImage) -> Void

        init(
            dismiss: DismissAction,
            onImagePicked: @escaping (UIImage) -> Void
        ) {
            self.dismiss = dismiss
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }

            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

private struct InlineArtStyleOption: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            Image(inlineArtStyleAssetName(for: title))
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.storyPurple : Color.storyBorder.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white, Color.storyPurple)
                            .padding(5)
                    }
                }

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isSelected ? Color.storyPurple : Color.storyInk.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 96)
        }
    }
}

private func inlineArtStyleAssetName(for title: String) -> String {
    switch title {
    case "Anime":
        return "inline_art_style_anime"
    case "Graphic Novel":
        return "inline_art_style_graphic_novel"
    case "Pixel Art":
        return "inline_art_style_pixel_art"
    case "Manga":
        return "inline_art_style_manga"
    case "Cozy Storybook":
        return "inline_art_style_cozy_storybook"
    case "Pop Art":
        return "inline_art_style_pop_art"
    case "Colored Journal":
        return "inline_art_style_colored_journal"
    default:
        return "inline_art_style_anime"
    }
}

private func artStylePromptDescription(for title: String) -> String {
switch title {

    case "Anime":
        return """
        Authentic modern anime artwork. Strongly stylized anime characters with large expressive eyes, simplified facial features, clean cel shading, vibrant colors, dramatic lighting, and dynamic poses.
        NOT photorealistic.
        Preserve identity but reinterpret all people as anime characters. Do not preserve realistic skin textures, facial proportions, or photographic details.
        The final result should look like a frame from a high-budget anime series, not a photograph with anime effects applied.
        """

    case "Graphic Novel":
        return """
        Premium western graphic novel artwork. Bold ink outlines, dramatic shadows, cinematic composition, painterly rendering, graphic shapes, and highly stylized comic-book storytelling.
        NOT photorealistic.
        Characters should look illustrated and artist-rendered rather than realistic. Use strong visual stylization, dramatic contrast, and graphic novel energy.
        The final result should look like published graphic novel artwork, not a painted photograph.
        """

    case "Pixel Art":
        return """
        Authentic 16-bit pixel art video game artwork. Large visible pixels, pixel-perfect edges, limited color palette, sprite-like characters, retro RPG environments, and deliberate pixel construction throughout.
        ABSOLUTELY NO smooth illustration or photorealistic rendering.
        Every object, character, and background element must be visibly pixelated.
        The final image should look like a premium SNES-era RPG screenshot, not a normal illustration with a pixel filter.
        """

    case "Manga":
        return """
        Authentic Japanese manga artwork. Highly stylized manga characters with expressive eyes, exaggerated expressions, bold black inks, screentones, cross-hatching, speed lines, dramatic camera angles, and dynamic manga storytelling.
        NOT photorealistic.
        Preserve identity but transform all people into manga characters. Simplify facial features and strongly stylize proportions.
        The final result should look like pages from a published manga series, not a realistic black-and-white photograph.
        """

    case "Cozy Storybook":
        return """
        Whimsical storybook illustration. Hand-painted watercolor and gouache textures, warm colors, soft edges, charming character designs, dreamy environments, and magical storybook atmosphere.
        NOT photorealistic.
        Characters should feel illustrated, charming, and slightly idealized rather than realistic.
        The final result should look like artwork from a beautifully illustrated children's storybook.
        """

    case "Pop Art":
        return """
        Bold pop art comic artwork inspired by classic comic books and gallery pop art. Thick black outlines, flat saturated colors, strong graphic shapes, Ben-Day dots, poster-like composition, and exaggerated visual impact.
        NOT photorealistic.
        Simplify forms into graphic comic-book shapes and bold color blocks.
        The final result should look like authentic pop art illustration, not a photo with color effects.
        """

    case "Colored Journal":
        return """
        Hand-drawn illustrated journal artwork. Loose sketch lines, colored pencil textures, marker rendering, handwritten sketchbook energy, personal diary charm, and expressive imperfect drawing.
        NOT photorealistic.
        Everything should feel hand-drawn by an artist in a personal journal. Visible sketch lines, artistic imperfections, and traditional drawing textures are encouraged.
        The final result should look like illustrated journal pages, not realistic digital artwork.
        """

    default:
        return """
        Fully commit to the selected art style.
        Preserve identity but not realism.
        Reinterpret everything as stylized artwork rather than photography.
        """
    }   
}

private func artStyleAssetName(for title: String) -> String {
    switch title {
    case "Anime":
        return "art_style_anime"
    case "Graphic Novel":
        return "art_style_graphic_novel"
    case "Pixel Art":
        return "art_style_pixel_art"
    case "Manga":
        return "art_style_manga"
    case "Cozy Storybook":
        return "art_style_cozy_storybook"
    case "Pop Art":
        return "art_style_pop_art"
    case "Colored Journal":
        return "art_style_colored_journal"
    default:
        return "art_style_anime"
    }
}

private struct SectionTitle: View {
    let title: String
    let action: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .serif))
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

private struct HeaderIconButton: View {
    let systemName: String

    var body: some View {
        Button {
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color.storyInk)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfilePlaceholder: View {
    var size: CGFloat = 42

    var body: some View {
        Image("art_style_anime")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.storyInk.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct BottomNavigationBar: View {
    @Binding var selectedPage: StoryPage

    var body: some View {
        HStack {
            NavItem(
                title: "Home",
                systemName: selectedPage == .home ? "house.fill" : "house",
                isSelected: selectedPage == .home,
                selectedColor: .homeAccent
            ) {
                selectedPage = .home
            }
            Spacer()
            NavItem(
                title: "Explore",
                systemName: selectedPage == .explore ? "safari.fill" : "safari",
                isSelected: selectedPage == .explore,
                selectedColor: .homeAccent
            ) {
                selectedPage = .explore
            }
            Spacer()
            CreateNavItem(isSelected: selectedPage == .create, selectedColor: .homeAccent) {
                withAnimation(.snappy(duration: 0.32)) {
                    selectedPage = .create
                }
            }
            Spacer()
            NavItem(
                title: "Journal",
                systemName: selectedPage == .journal ? "book.closed.fill" : "book.closed",
                isSelected: selectedPage == .journal,
                selectedColor: .homeAccent
            ) {
                selectedPage = .journal
            }
            Spacer()
            NavItem(
                title: "Profile",
                systemName: selectedPage == .profile ? "person.fill" : "person",
                isSelected: selectedPage == .profile,
                selectedColor: .homeAccent
            ) {
                selectedPage = .profile
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.homeBorder)
                .frame(height: 1),
            alignment: .top
        )
    }
}

private struct NavItem: View {
    let title: String
    let systemName: String
    let isSelected: Bool
    var selectedColor: Color = .storyPurple
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 21, weight: isSelected ? .bold : .regular))

                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? selectedColor : Color.storyInk.opacity(0.82))
            .frame(width: 50, height: 44)
        }
    }
}

private struct CreateNavItem: View {
    let isSelected: Bool
    var selectedColor: Color = .storyPurple
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "plus.circle.fill" : "plus.circle")
                    .font(.system(size: 24, weight: isSelected ? .bold : .regular))

                Text("Create")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? selectedColor : Color.storyInk.opacity(0.82))
            }
            .foregroundStyle(isSelected ? selectedColor : Color.storyInk.opacity(0.82))
            .frame(width: 50, height: 44)
        }
    }
}

private extension Data {
    mutating func appendMultipartField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipartFile(
        name: String,
        fileName: String,
        mimeType: String,
        data: Data,
        boundary: String
    ) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}

private extension UIImage {
    func storytopiaPreparedJPEGData(maxDimension: CGFloat = 2048, compressionQuality: CGFloat = 0.82) -> Data? {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else {
            return jpegData(compressionQuality: compressionQuality)
        }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let resized = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized.jpegData(compressionQuality: compressionQuality)
    }
}

private extension Color {
    static let storyInk = Color(red: 0.08, green: 0.07, blue: 0.22)
    static let storyGray = Color(red: 0.39, green: 0.39, blue: 0.46)
    static let storyPurple = Color(uiColor: .systemIndigo)
    static let storyLavender = Color(red: 0.91, green: 0.86, blue: 0.98)
    static let storyRose = Color(red: 0.93, green: 0.73, blue: 0.70)
    static let storyBlush = Color(red: 0.99, green: 0.95, blue: 0.92)
    static let storyCream = Color(red: 1.0, green: 0.98, blue: 0.94)
    static let storySoftPink = Color(red: 0.96, green: 0.90, blue: 0.89)
    static let storyPeach = Color(red: 0.93, green: 0.63, blue: 0.45)
    static let storyGold = Color(red: 0.95, green: 0.69, blue: 0.34)
    static let storyBorder = Color(red: 0.88, green: 0.80, blue: 0.78)
    static let homePageBackground = Color(red: 0.949, green: 0.949, blue: 0.969)
    static let homeCardGray = Color(uiColor: .systemGray6)
    static let homeInputGray = Color(red: 0.92, green: 0.92, blue: 0.94)
    static let homeMutedText = Color(red: 0.43, green: 0.44, blue: 0.54)
    static let homeBorder = Color(red: 0.86, green: 0.87, blue: 0.91)
    static let homeAccent = Color(uiColor: .systemIndigo)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

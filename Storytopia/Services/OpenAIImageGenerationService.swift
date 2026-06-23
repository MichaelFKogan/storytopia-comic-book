import Foundation
import UIKit

struct OpenAIImageGenerationService {
    private let editsEndpoint = URL(string: "https://api.openai.com/v1/images/edits")!
    private let generationsEndpoint = URL(string: "https://api.openai.com/v1/images/generations")!
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

        let prompt = makePrompt(text: text, artStyle: artStyle, layout: layout, imageCount: images.count)
        let data = try await images.isEmpty
            ? generateStoryboardWithoutReferences(apiKey: apiKey, prompt: prompt)
            : generateStoryboardWithReferences(apiKey: apiKey, prompt: prompt, images: images)

        guard
            let imageData = Data(base64Encoded: data),
            let image = UIImage(data: imageData)
        else {
            throw StoryboardGenerationError.noGeneratedImage
        }

        return image
    }

    private func generateStoryboardWithReferences(
        apiKey: String,
        prompt: String,
        images: [UIImage]
    ) async throws -> String {
        var request = URLRequest(url: editsEndpoint)
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

        for (index, image) in images.prefix(5).enumerated() {
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

        return try await performImageRequest(request)
    }

    private func generateStoryboardWithoutReferences(
        apiKey: String,
        prompt: String
    ) async throws -> String {
        var request = URLRequest(url: generationsEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: String] = [
            "model": OpenAITestConfig.imageModel,
            "prompt": prompt,
            "size": "1024x1536",
            "quality": "medium"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performImageRequest(request)
    }

    private func performImageRequest(_ request: URLRequest) async throws -> String {
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
        guard let base64Image = decoded.data.first?.b64JSON else {
            throw StoryboardGenerationError.noGeneratedImage
        }

        return base64Image
    }

    private func makePrompt(
        text: String,
        artStyle: String,
        layout: StoryboardLayoutOption,
        imageCount: Int
    ) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasReferencePhotos = imageCount > 0
        let storyText: String

        if trimmedText.isEmpty {
            storyText = hasReferencePhotos
                ? "No written story was provided. Infer a warm, visually coherent story about the moment from the uploaded photos."
                : "No written story or reference photos were provided. Invent a warm, visually coherent everyday moment with a clear beginning, middle, and end."
        } else {
            storyText = trimmedText
        }

        let referencePhotoCount = min(imageCount, 5)
        let creationSource = hasReferencePhotos
            ? "using the user's \(referencePhotoCount) uploaded reference photo(s) and optional written story"
            : "from the user's written story"
        let identityInstruction = hasReferencePhotos
            ? "Preserve the identity of people, pets, locations, clothing, and important objects from the reference photos, but DO NOT preserve photographic realism."
            : "Create appealing, consistent characters, locations, clothing, and important objects that fit the user's story."
        let referencePhotoInstructions = hasReferencePhotos
            ? """
            REFERENCE PHOTOS:
            - Use ALL uploaded reference photos.
            - Do not ignore uploaded photos.
            - Use them as references for identity, pets, clothing, objects, locations, mood, and story details.
            - Do NOT map photo 1 to panel 1, photo 2 to panel 2, and so on.
            - You may combine details from multiple photos when it improves storytelling.
            - Keep characters and important visual elements recognizable and consistent across panels.
            - Reimagine every scene in the selected art style rather than recreating the original photographs.
            """
            : """
            REFERENCE PHOTOS:
            - No reference photos were provided.
            - Do not imply that a photo reference exists.
            - Build the storyboard from the written story, selected art style, and a coherent invented scene when details are missing.
            - Keep characters and important visual elements consistent across panels.
            """

        return """
        Create a vertical illustrated comic/storyboard about the moment \(creationSource).

        USER STORY:
        \(storyText)

        ART STYLE:
        \(artStyle)

        STYLE PRIORITY — this is the most important instruction:
        \(artStylePromptDescription(for: artStyle))

        The final image must fully commit to the selected art style.
        \(identityInstruction)
        Strongly reinterpret everything in the selected style.
        The result should look like authentic \(artStyle) artwork, not a photograph with an art filter applied.
        When there is a conflict between realism and the selected art style, always prioritize the selected art style.

        FORMAT:
        - Output ONE single tall image divided into exactly 5 distinct comic panels with visible gutters or borders.
        - Panel layout (top to bottom): \(layout.promptDescription)
        - Create a coherent beginning, middle, and end.
        - Show a progression of events rather than repeating the same scene.
        - Generate a true illustrated comic/storyboard.
        - Never create a photo collage, contact sheet, photomontage, or collection of separate photos.
        - Fully redraw every scene as original illustrated artwork.

        \(referencePhotoInstructions)

        TEXT:
        - Include readable text in every panel.
        - Use concise captions and/or speech bubbles that support the story.
        - Keep text short enough to fit cleanly inside each panel.
        - Prioritize visual storytelling.
        """
    }
}

func storyboardPanelCount(for imageCount: Int) -> Int {
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

struct OpenAIImageResponse: Decodable {
    struct ImageData: Decodable {
        let b64JSON: String?

        private enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
        }
    }

    let data: [ImageData]
}

struct OpenAIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}

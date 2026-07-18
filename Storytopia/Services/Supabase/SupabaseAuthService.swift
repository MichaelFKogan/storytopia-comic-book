import AuthenticationServices
import Combine
import Foundation
import Supabase
import UIKit

@MainActor
final class SupabaseAuthStore: ObservableObject {
    enum AuthStatus: Equatable {
        case loading
        case signedOut
        case signedIn
        case misconfigured(String)
    }

    @Published private(set) var status: AuthStatus = .loading
    @Published private(set) var currentUser: User?
    @Published var errorMessage: String?

    private let client: SupabaseClient
    private var authStateTask: Task<Void, Never>?

    var userID: UUID? {
        currentUser?.id
    }

    var displayName: String {
        currentUser?.email ?? "Signed in"
    }

    init(client: SupabaseClient = SupabaseService.shared) {
        self.client = client
        validateConfiguration()
        startListening()
    }

    deinit {
        authStateTask?.cancel()
    }

    func signInWithGoogle() async {
        errorMessage = nil

        do {
            _ = try StorytopiaSupabaseConfig.projectURL
            _ = try StorytopiaSupabaseConfig.anonKey

            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: StorytopiaSupabaseConfig.redirectURL
            ) { session in
                session.presentationContextProvider = AuthPresentationContextProvider.shared
                session.prefersEphemeralWebBrowserSession = false
            }
        } catch {
            status = .signedOut
            errorMessage = userFacingMessage(for: error)
        }
    }

    func signOut() async {
        errorMessage = nil

        do {
            try await client.auth.signOut()
            currentUser = nil
            status = .signedOut
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    func refreshCurrentUser() async {
        if case .misconfigured = status {
            return
        }

        do {
            let session = try await client.auth.session
            currentUser = session.user
            status = .signedIn
        } catch {
            currentUser = nil
            status = .signedOut
        }
    }

    func handleOpenURL(_ url: URL) {
        client.auth.handle(url)
    }

    private func validateConfiguration() {
        do {
            _ = try StorytopiaSupabaseConfig.projectURL
            _ = try StorytopiaSupabaseConfig.anonKey
        } catch {
            status = .misconfigured(userFacingMessage(for: error))
        }
    }

    private func startListening() {
        authStateTask?.cancel()
        authStateTask = Task { [weak self] in
            guard let self else { return }

            for await (_, session) in await client.auth.authStateChanges {
                await MainActor.run {
                    if case .misconfigured = self.status {
                        return
                    }

                    self.currentUser = session?.user
                    self.status = session == nil ? .signedOut : .signedIn
                }
            }
        }
    }

    private func userFacingMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return "Authentication is unavailable right now. Please try again."
    }
}

final class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

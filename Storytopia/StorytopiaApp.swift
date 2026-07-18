//
//  StorytopiaApp.swift
//  Storytopia
//
//  Created by Mike Kogan on 5/28/26.
//

import SwiftUI

@main
struct StorytopiaApp: App {
    @StateObject private var authStore = SupabaseAuthStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStore)
                .onOpenURL { url in
                    authStore.handleOpenURL(url)
                }
        }
    }
}

//
//  ContentView.swift
//  Storytopia
//
//  Created by Mike Kogan on 5/28/26.
//

import SwiftUI

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
            HomeView(selectedPage: $selectedPage)
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
            .transition(.identity)
            .zIndex(0)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

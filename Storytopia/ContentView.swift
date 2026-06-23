//
//  ContentView.swift
//  Storytopia
//
//  Created by Mike Kogan on 5/28/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedPage: StoryPage = .home
    @State private var entryText: String
    @State private var draftStoryTitle: String
    @State private var draftStoryboardPhotos: [UIImage?]
    @State private var isDraftSaved: Bool
    @State private var activeDraftID: UUID?
    @State private var generatedStoryboards: [GeneratedStoryboard]

    init() {
        let drafts = CreateEntryDraftStore.loadAll()
        _entryText = State(initialValue: "")
        _draftStoryTitle = State(initialValue: "")
        _draftStoryboardPhotos = State(initialValue: Array(repeating: nil, count: 5))
        _isDraftSaved = State(initialValue: !drafts.isEmpty)
        _activeDraftID = State(initialValue: nil)
        _generatedStoryboards = State(initialValue: GeneratedStoryboardStore.load())
    }

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
        case .today:
            DaybookView(selectedPage: $selectedPage)
                .transition(.identity)
                .zIndex(0)
        case .explore:
            ExploreView(selectedPage: $selectedPage)
                .transition(.identity)
                .zIndex(0)
        case .create:
            CreateEntryView(
                entryText: $entryText,
                storyTitle: $draftStoryTitle,
                storyboardPhotos: $draftStoryboardPhotos,
                isDraftSaved: $isDraftSaved,
                activeDraftID: $activeDraftID,
                selectedPage: $selectedPage,
                generatedStoryboards: $generatedStoryboards
            )
            .transition(.identity)
            .zIndex(0)
        case .journal:
            JournalView(
                selectedPage: $selectedPage,
                isDraftSaved: $isDraftSaved,
                activeDraftID: $activeDraftID
            )
                .transition(.identity)
                .zIndex(0)
        case .profile:
            ProfileView(
                selectedPage: $selectedPage,
                generatedStoryboards: $generatedStoryboards
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

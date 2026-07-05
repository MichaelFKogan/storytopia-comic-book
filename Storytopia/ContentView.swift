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
    @State private var pageBehindCreate: StoryPage = .home
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
            basePage

            if selectedPage == .create {
                createPage
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(.snappy(duration: 0.32), value: selectedPage)
    }

    private var pageSelection: Binding<StoryPage> {
        Binding(
            get: { selectedPage },
            set: { newPage in
                if newPage == .create {
                    if selectedPage != .create {
                        pageBehindCreate = selectedPage
                    }
                } else {
                    pageBehindCreate = newPage
                }

                selectedPage = newPage
            }
        )
    }

    @ViewBuilder
    private var basePage: some View {
        switch pageBehindCreate {
        case .home:
            HomeView(selectedPage: pageSelection)
                .transition(.identity)
                .zIndex(0)
        case .today:
            DaybookView(selectedPage: pageSelection)
                .transition(.identity)
                .zIndex(0)
        case .explore:
            ExploreView(selectedPage: pageSelection)
                .transition(.identity)
                .zIndex(0)
        case .entries:
            EntriesView(
                selectedPage: pageSelection,
                isDraftSaved: $isDraftSaved,
                activeDraftID: $activeDraftID
            )
                .transition(.identity)
                .zIndex(0)
        case .journal:
            JournalView(
                selectedPage: pageSelection,
                isDraftSaved: $isDraftSaved,
                activeDraftID: $activeDraftID
            )
                .transition(.identity)
                .zIndex(0)
        case .profile:
            ProfileView(
                selectedPage: pageSelection,
                generatedStoryboards: $generatedStoryboards
            )
            .transition(.identity)
            .zIndex(0)
        case .settings:
            NavigationStack {
                SettingsView(selectedPage: pageSelection)
            }
                .transition(.identity)
                .zIndex(0)
        case .create:
            EmptyView()
        }
    }

    private var createPage: some View {
        CreateEntryView(
            entryText: $entryText,
            storyTitle: $draftStoryTitle,
            storyboardPhotos: $draftStoryboardPhotos,
            isDraftSaved: $isDraftSaved,
            activeDraftID: $activeDraftID,
            selectedPage: pageSelection,
            generatedStoryboards: $generatedStoryboards,
            dismissCreate: {
                selectedPage = pageBehindCreate
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

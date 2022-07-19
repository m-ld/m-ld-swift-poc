//
//  ContentView.swift
//  iOSConferences
//
//  Created by George on 12/07/2022.
//
//

import SwiftUI
import Combine

struct ConferenceList: View {
    /// Domain to work with (loading from JSON, for now)
    let domain: OrmDomain = JsonDomain()
    /// Keeping track in the view of the visible loaded conferences, see
    /// ``body`` & ``onAppear()``. If we wanted to limit the visible list (for
    /// example with paging, or infinite scroll), this would be a subset of all
    /// available conferences.
    /// TODO: Provide SwiftUI State & Binding library classes instead?
    @State var conferences: [Conference] = []

    var body: some View {
        NavigationView {
            var subs = Set<AnyCancellable>()
            List(conferences, rowContent: conferenceRow)
                .task { subs.formUnion(await onAppear()) }
                .onDisappear { subs.removeAll() }
                .navigationBarTitle("Conferences")
        }
    }

    private func conferenceRow(conference: Conference) -> some View {
        NavigationLink(destination: ConferenceDetails(conference: conference)) {
            VStack(alignment: .leading) {
                Text(conference.name).font(.headline)
                Text(conference.location).font(.subheadline)
            }
        }
    }

    private func onAppear() async -> Set<AnyCancellable> {
        var subs = Set<AnyCancellable>()
        // Obtain a snapshot state to work with. Note this goes out of scope
        // synchronously at the end of this method, but that's OK because the
        // state.all() query guarantees consistency of its results regardless
        let state = await domain.state()
        if !Task.isCancelled {
            // Retrieve all conferences from the state when the List appears
            state.all(of: Conference.self)
                .sink(
                    receiveCompletion: { completion in
                        // TODO: UI error handling
                        if case let .failure(error) = completion {
                            fatalError("\(error)")
                        }
                    },
                    receiveValue: { conference in
                        // Add each existing conference to the UI-local array
                        if !conferences.contains(where: { $0.id == conference.id }) {
                            conferences.append(conference)
                        }
                        // If a conference becomes deleted, remove it
                        conference.$deleted
                            .sink { deleted in
                                if deleted {
                                    conferences.removeAll { $0.id == conference.id }
                                }
                            }
                            .store(in: &subs)
                    })
                .store(in: &subs)
        }
        return subs
    }
}

class ConferenceList_Previews: PreviewProvider {
    static var previews: some View {
        ConferenceList()
    }

    #if DEBUG
    @objc class func injected() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.rootViewController =
            UIHostingController(rootView: ConferenceList())
    }
    #endif
}

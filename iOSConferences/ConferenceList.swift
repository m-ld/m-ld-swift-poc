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
    /// Keeping track in the view of the available conferences, see body & onAppear()
    @State var conferences: [Conference] = []

    func conferenceRow(conference: Conference) -> some View {
        NavigationLink(destination: ConferenceDetails(conference: conference)) {
            VStack(alignment: .leading) {
                Text(conference.name).font(.headline)
                Text(conference.location).font(.subheadline)
            }
        }
    }

    var body: some View {
        NavigationView {
            var subs = Set<AnyCancellable>()
            List(conferences, rowContent: conferenceRow)
                .task { subs.formUnion(await onAppear()) }
                .onDisappear { subs.removeAll() }
                .navigationBarTitle("Conferences")
        }
    }

    private func onAppear() async -> Set<AnyCancellable> {
        var subs = Set<AnyCancellable>()
        // Obtain a snapshot state to work with. Note this goes out of scope
        // synchronously at the end of this method, but that's OK because the
        // state.all() query guarantees consistency regardless
        let state = await domain.state()
        if !Task.isCancelled {
            state.all(of: Conference.self)
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            fatalError("\(error)")
                        }
                    },
                    receiveValue: { conference in
                        if !conferences.contains(where: { $0.id == conference.id }) {
                            conferences.append(conference)
                        }
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

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
    @ObservedObject var conferences = AllConferences(domain: JsonDomain())

    var body: some View {
        NavigationView {
            List($conferences.conferences, rowContent: conferenceRow)
                .navigationBarTitle("Conferences")
        }
    }

    private func conferenceRow(conference: Binding<Conference>) -> some View {
        NavigationLink(destination: ConferenceDetails(conference: conference.wrappedValue)) {
            VStack(alignment: .leading) {
                Text(conference.name.wrappedValue).font(.headline)
                Text(conference.location.wrappedValue).font(.subheadline)
            }
        }
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

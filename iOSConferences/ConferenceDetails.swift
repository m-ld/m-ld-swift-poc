//
//  ConferenceDetails.swift
//  iOSConferences
//
//  Created by George on 12/07/2022.
//
//

import SwiftUI

struct ConferenceDetails: View {
    var conference: Conference
    var body: some View {
        VStack(alignment: .leading) {
            Text(conference.location).padding(.bottom)
            Text(conference.textDates()).padding(.bottom)
            LinkButton(link: conference.link).padding(.bottom)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity,
                alignment: .topLeading)
         .padding()
         .navigationBarTitle(conference.name)
    }
}

struct LinkButton: View {
    var link = ""
    var body: some View {
        Button(action: {
            UIApplication.shared.open(URL(string: link)!)
        }) {
            Text("Go to official website")
        }
    }
}
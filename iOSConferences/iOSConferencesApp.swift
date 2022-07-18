//
//  iOSConferencesApp.swift
//  iOSConferences
//
//  Created by George on 12/07/2022.
//
//

import SwiftUI

@main
struct iOSConferencesApp: App {
    let confDomain = JsonDomain()

    init() {
        #if DEBUG
        var injectionBundlePath = "/Applications/InjectionIII.app/Contents/Resources"
        #if targetEnvironment(macCatalyst)
        injectionBundlePath = "\(injectionBundlePath)/macOSInjection.bundle"
        #elseif os(iOS)
        injectionBundlePath = "\(injectionBundlePath)/iOSInjection.bundle"
        #endif
        Bundle(path: injectionBundlePath)?.load()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ConferenceList()
        }
    }
}

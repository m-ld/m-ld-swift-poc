# m-ld Swift API Mock-Up

Experimental mock-up of an idiomatic Swift API built over a putative core [**m-ld** clone API](https://spec.m-ld.org/#clone-api) on Apple platforms.

## entry points

- Object-RDF Mapping (ORM) API as annotated Swift protocols ([iOSConferences/Meld/Orm.swift](iOSConferences/Meld/Orm.swift))
- Example Swift class for an ORM-managed object (a Conference; [iOSConferences/Model/Conference.swift](iOSConferences/Model/Conference.swift))
- Example SwiftUI classes demonstrating possible usage ([iOSConferences/ConferenceList.swift](iOSConferences/ConferenceList.swift))
- JSON file-based ORM partial implementation mock-up ([iOSConferences/Meld/Engine/JsonDomain.swift](iOSConferences/Meld/Engine/JsonDomain.swift))

## summary

A **m-ld** "clone" takes the place of a Model in a conventional UI, with the benefit that it automatically stays up-to-date with changes made on other devices, with an eventual consistency guarantee. The core clone API is standardised across all platforms, based on JSON representation of RDF graphs, updates and queries; but on a specific platform an engine can benefit from an additional API layer that  matches the local idioms.

The proposed Swift API is:
- Object-oriented: information content is represented using classes having mutable state.
- Reactive: changes to information are published to the app using [Combine](https://developer.apple.com/documentation/combine).
- Based on Swift 5.5 concurrency, including async/await, structured concurrency, and Actors.
- Intended to hide **m-ld** constructs where a Swift pattern exists, for example using [Codable](https://developer.apple.com/documentation/swift/codable) for serialisation.

The general usage pattern of this API by the app is:
1. Instantiate a local clone representing the domain (details TODO)
2. Make some selection of subjects (entities) from the domain using a query (at present, filtering by type)
3. The subjects are realised as mutable objects of an application-provided class, implementing a protocol
4. Each subject's reference graph (via properties) is transparently included
5. Changes to the loaded graph are notified to the app via publishers
6. The app can also stall remote changes while it makes local changes which are then committed in batch

## acknowledgements

Based on https://github.com/JetBrains/ac_tutorial_swiftui

## see also

- [Javascript clone engine](https://js.m-ld.org/) (core API)
- [Experimental Javascript ORM](https://github.com/m-ld/m-ld-js/tree/edge/src/orm)
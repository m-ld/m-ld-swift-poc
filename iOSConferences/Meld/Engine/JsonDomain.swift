//
// Created by George on 14/07/2022.
//

import Foundation
import Combine

/// A very naive implementation of an OrmDomain, which loads data from a JSON file
actor JsonDomain: OrmDomain {
    /// Load the data from the JSON file. Note that the data will get sent between threads
    /// in the state() method
    let data = loadFileData(filename: "conferencesData.json")

    /// Having an active state should indicate that no remote operations are applied.
    /// This property just shows one way that "having an active state" could be implemented.
    var hasActiveState = 0 {
        didSet {
            print("States active: \(hasActiveState)")
        }
    }

    var state: @Sendable () -> OrmState {
        get async {
            // This happens on the actor's thread
            hasActiveState = hasActiveState + 1
            return {
                // This happens on the caller's thread
                JsonState(self.data, self)
            }
        }
    }

    func inactivate() {
        hasActiveState = hasActiveState - 1
    }
}

final class JsonState: OrmState {
    let domain: JsonDomain

    /// Hard-coded to Conferences for simplicity.
    /// TODO: Generalise to any OrmSubject class
    let conferences: [Conference]

    init(_ data: Data, _ domain: JsonDomain) {
        self.domain = domain
        conferences = loadEncoded(data)
    }

    deinit {
        let domain = domain
        Task.detached {
            // De-activate the locked state when this object de-scopes
            await domain.inactivate()
        }
    }

    func all<S>(of type: S.Type) -> AnyPublisher<S, Error> {
        switch type {
        case is Conference.Type:
            return Publishers
                .Sequence<[S], Error>(sequence: conferences as! [S])
                // TODO: Relay any new subjects
                .append(Empty(completeImmediately: false))
                .eraseToAnyPublisher()
        default:
            return Empty().eraseToAnyPublisher()
        }
    }

    func get<S: OrmSubject>(_ id: String, of type: S.Type) async throws -> S {
        switch type {
        case is Conference.Type:
            if let conference = conferences.first(where: { $0.id == id }) as? S {
                return conference
            } else {
                // FIXME does not match spec: should return a deleted conference
                throw OrmError.notFound
            }
        default:
            // FIXME does not match spec: type is provided & should be used
            throw OrmError.unsupportedType
        }
    }

    func commit() async throws {
        // TODO
    }
}

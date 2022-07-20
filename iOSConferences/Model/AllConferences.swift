//
// Created by George on 20/07/2022.
//

import Foundation
import Combine

/**
 Model class demonstrating one way to maintain a collection of subjects from the
 domain, in this case all available conferences. More sophisticated models could
 limit the number of objects in memory, for example by paging, or dynamic
 loading for infinite scroll.
 */
class AllConferences: ObservableObject {
    @Published var conferences: [Conference] = []
    var subs = Set<AnyCancellable>()

    init(domain: OrmDomain) {
        Task {
            // Obtain a snapshot state to work with. Note this goes out of scope
            // synchronously at the end of this block, but that's OK because the
            // state.all() query guarantees consistency of its results regardless
            let state = await domain.state()
            guard !Task.isCancelled else { return }
            // Retrieve all conferences from the state when the List appears
            state.all(of: Conference.self)
                .sink(
                    receiveCompletion: onComplete,
                    receiveValue: addConference
                )
                .store(in: &subs)
        }
    }

    private func addConference(conference: Conference) {
        // Add an existing conference to the local array
        conferences.append(conference)
        // If a conference becomes deleted, remove it
        conference.$deleted
            .filter { deleted in deleted }
            .sink { [self] deleted in
                conferences.removeAll { $0.id == conference.id }
            }
            .store(in: &subs)
    }

    private func onComplete(completion: Subscribers.Completion<Error>) {
        // TODO: proper error handling
        if case let .failure(error) = completion {
            fatalError("\(error)")
        }
    }
}

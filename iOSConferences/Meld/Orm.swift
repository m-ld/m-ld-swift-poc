//
// Created by George on 13/07/2022.
//

import Foundation
import Combine

/**
 A **m-ld** _domain_ is a logical, decentralised set of shared information. The
 content may at any moment differ slightly between clones, but in the absence of
 any writes, and with a live connection, then all clones will 'converge' on an
 identical set of data, as fast as the network can carry the latest changes.

 Object-RDF Mapping (ORM) is the translation of the domain content into
 idiomatic object-oriented Swift constructs (OrmSubjects) in memory, and
 typically on the main application thread, where they can be manipulated.

 An OrmDomain is a Swift Actor because changes to information state are strictly
 serialised from the point of view of the app (even though they may actually be
 concurrent on separate devices; the availability of this simplification is a
 key benefit of using **m-ld**).

 > 🚧 TODO: how is a domain actor initially obtained?
 */
protocol OrmDomain: Actor {
    /**
     Obtain a snapshot state to work with. This property dynamically gives
     access to a state-creation function, which should be immediately called on
     the consumer's thread.
     - See: OrmState
     */
    var state: @Sendable () -> OrmState { get async }
}

/**
 A mutable, observable subject of discourse in the data domain.

 An instance of a class implementing this protocol will correspond to a
 [_subject_](https://spec.m-ld.org/#subjects) in a shared **m-ld** domain.
 Instances must be created using the ``OrmState/get`` method. Once created, they
 can be mutated using normal property setters. Changes made locally can be
 shared transparently and immediately, or can contribute to a 'transaction'
 against a consistent domain state, which delays sharing until the state is
 de-initialised (see ``OrmState``).

 Remote clones participating in the domain may also cause an OrmSubject to
 mutate. Such changes are applied automatically to OrmSubjects, and can be
 notified to user interface constructs via `@Published` properties.

 OrmSubjects are not thread-safe. All mutations MUST be made on one thread,
 typically the main app thread. This can be assured by marking the class as
 `@MainThread`. In a multi-threaded app, separate instances of an OrmSubject
 can be used on each different thread; they will stay in-sync as if they are in
 separate processes or nodes.

 An OrmSubject is serialised to and from the domain via its `Codable`
 implementation. Since remote mutations can happen at any time, the atypical
 ``decode`` method is required in addition to the `Codable` protocol.
 */
protocol OrmSubject: Identifiable, Codable, ObservableObject {
    /**
     All subjects have a String ID (actually an IRI, relative to the domain).
     Subject IDs must be unique not just for this type but across all subjects
     in the domain.
     */
    associatedtype ID = String
    /**
     Update property content from the given decoder. Since this method will
     typically set all properties regardless of whether they have changed, care
     may be required in downstream listeners to avoid duplicating work.

     This method will normally be called from the ``init(decoder)`` initializer
     once the subject ID has been set.
     - Parameter decoder: The decoder to read data from.
     - Throws: if an error occurs in decoding
     */
    func decode(from decoder: Decoder) throws
    /**
     Indicates whether this subject has been deleted, or is about to be deleted,
     in the domain. This flag is necessary because an OrmSubject going out of
     scope (and so de-initialising) may only indicate that it is no longer of
     interest to the local app or user, not necessarily that it should be
     deleted.

     In particular, removing an OrmSubject reference from some other
     OrmSubject's graph, for example in a property, or in a collection property,
     DOES NOT automatically cause it to be deleted. (There is no garbage
     collection based on references in a **m-ld** domain.)

     Similarly, setting this flag DOES NOT cause this subject to be
     automatically removed from some other subject's visible graph.

     > 🚧 Since this approach may sometimes breach the principle of least
     surprise, in future we hope to have a way to mark subject 'owners', so that
     deletes are cascaded through reference properties in an intuitive way.
     */
    var deleted: Bool { get }
}

/**
 A snapshot state of the domain. While a state is active, no remote changes
 are applied to the OrmSubjects in the domain. Local changes can be made, but
 they are not transmitted to other clones until the state is committed OR de-
 initialises. Use of a state is required in order to obtain an OrmSubject.
 Once the state is unreferenced, remote changes will be applied to all subjects
 once more.

 Having an active state is not _required_ to make changes to subjects after
 their initial creation. However one may be appropriate to group together
 multiple local changes made in succession (akin to a transaction against an SQL
 database).

 > 🚧 The available state-reading methods do not provide the expressiveness of
 **m-ld**'s query language, json-rql. We'll iterate on more expressive methods
 *as required.
 */
protocol OrmState {
    /**
     Retrieve a single OrmSubject and its properties by its identity. If the
     subject does not exist in the domain, a new OrmSubject will be minted,
     whose `deleted` flag will be `true` (thus representing a subject that is
     not in the domain).
     - Parameters:
       - id: identity of the subject (relative or absolute IRI)
       - type: type of the subject. If the given ID exists in the domain but has
       a different type, the method will throw an error
     - Returns: an OrmSubject with the given type
     - Throws: if the subject in the domain has the wrong type
     */
    func get<S: OrmSubject>(_ id: String, of type: S.Type) async throws -> S
    /**
     Retrieve all OrmSubjects of a particular type in the domain.

     The returned publisher does NOT complete when all matching subjects have
     been emitted. Instead, it will continue to emit any new matching
     (non-deleted) subjects created either locally or remotely.

     The state may de-activate independently of the returned publisher. Whether
     still emitting subjects from the state snapshot, or new subjects being
     created, the publisher is guaranteed to present a reliably consistent view.
     (E.g. not missing any subjects or misrepresenting deleted status.)
     - Parameter type: type of the subject
     - Returns: a stream of subjects
     */
    func all<S: OrmSubject>(of type: S.Type) -> AnyPublisher<S, Error>
    /**
     Optionally, commit any Subject changes to the domain. You can also just let
     the state de-initialise; but this method allows error handling.
     */
    func commit() async throws
}

/**
 The default coding keys of a subject
 */
enum OrmKey: String, CodingKey {

    /// Subject identity: a relative IRI
    case id = "@id"
    /// Subject type: a vocabulary IRI. For OrmSubjects this is always the
    /// class name (and so is usually implicit).
    case type = "@type"
    /**
     Decode only the ID property for the current OrmSubject. To be used in
     OrmSubject initialisers.
     - Parameter decoder: The decoder to read data from.
     - Returns: the subject ID
     - Throws: if an error occurs in decoding
     */
    static func decodeId(_ decoder: Decoder) throws -> String {
        try decoder
            .container(keyedBy: OrmKey.self)
            .decode(String.self, forKey: .id)
    }
}

/**
 Extension to the standard `Decoder` API to support the ``OrmSubject/deleted``
 flag. The internal Decoder used by an OrmDomain may have this flag set to
 `true`. If so, an OrmSubject should not attempt to read any property values,
 but only set its own `deleted` flag.
 */
extension KeyedDecodingContainerProtocol {
    var deleted: Bool {
        get {
            false
        }
    }
}

enum OrmError: Error {
    /// Subject not found
    @available(*, deprecated, message: "Never emitted by a correct API")
    case notFound
    /// Requested subject type has no local class
    @available(*, deprecated, message: "Never emitted by a correct API")
    case unsupportedType
}

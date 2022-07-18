//
// Created by George on 13/07/2022.
//

import Foundation
import Combine

class Conference: OrmSubject {
    enum ConferenceKey: String, CodingKey {
        case id = "@id", name, location, start, end, link
    }
    let id: String
    // *** Mutable properties ***
    // Note: implicitly unwrapped optionals allow init() to call decode()
    // Note: shame that using @Published fields introduces so much boilerplate
    // See https://developer.apple.com/forums/thread/127345
    @Published var name: String!
    @Published var location: String!
    @Published var start: Date!
    @Published var end: Date?
    @Published var link: String!
    @Published var deleted = false

    required init(from decoder: Decoder) throws {
        id = try OrmKey.decodeId(decoder)
        try decode(from: decoder)
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ConferenceKey.self)
        // First check that the subject is not deleted
        guard !container.deleted else {
            // Note that this introduces the possibility that the implicitly
            // unwrapped properties below are never initialised to a value.
            // Users of OrmSubjects should be aware of this.
            return deleted = true
        }
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        start = try container.decode(Date.self, forKey: .start)
        end = try container.decode(Date.self, forKey: .end)
        link = try container.decode(String.self, forKey: .link)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ConferenceKey.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(location, forKey: .location)
        try container.encode(start, forKey: .start)
        try container.encode(end, forKey: .end)
        try container.encode(link, forKey: .link)
    }

    func textDates() -> String {
        var result = start.dateToString()
        if let end = end {
            result = "\(result) - \(end.dateToString())"
        }
        return result
    }
}
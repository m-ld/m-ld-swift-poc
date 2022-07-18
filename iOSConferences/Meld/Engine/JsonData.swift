//
// Created by George on 13/07/2022.
//

import Foundation

func loadEncoded<T: Decodable>(_ data: Data) -> T {
    do {
        let decoder = JSONDecoder()
        let format = DateFormatter()
        format.dateFormat = "yyyy-mm-dd"
        decoder.dateDecodingStrategy = .formatted(format)
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Cannot parse data: \(T.self):\n\(error)")
    }
}

func loadFileData(filename: String) -> Data {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Cannot find \(filename)")
    }
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Cannot load \(filename):\n\(error)")
    }
    return data
}

extension Date {
    func dateToString() -> String {
        let format = DateFormatter()
        format.dateFormat = "MMM dd, yyyy"
        return format.string(from: self)
    }
}
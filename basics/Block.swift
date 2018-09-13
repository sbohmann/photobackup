
import Foundation

func blockToString(_ block: [UInt8]) -> String {
    return block.map({ String(format: "%02hhx", $0) }).joined(separator: "")
}

func parseBlock(_ string: String, _ length: Int) throws -> [UInt8] {
    try checkStringLength(string, length)
    var value = [UInt8](repeating: 0, count: length)
    for index in 0 ..< length {
        let position = index * 2
        value[index] = try parseByte(string, position)
    }
    return value
}

private func parseByte(_ string: String, _ position: Int) throws -> UInt8 {
    let start = string.index(string.startIndex, offsetBy: position)
    let end = string.index(string.startIndex, offsetBy: position + 2)
    let fuck: Substring = string[start ..< end]
    if let result = UInt8(fuck, radix: 16) {
        return result
    } else {
        throw InvalidArgument("string [\(string)], position \(position)")
    }
}

private func checkStringLength(_ string: String, _ length: Int) throws {
    if string.count != length * 2 {
        throw InvalidArgument("Illegal checksum string [\(string)]" +
            " of length \(string.count) - expected: \(length * 2)")
    }
}

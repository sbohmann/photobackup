
private let Length = 64

struct Checksum : CustomStringConvertible {
    let value: [UInt8]

    init(value: [UInt8]) throws {
        try value.CheckSize(Length)
        self.value = value
    }

    init(checksumString: String) throws {
        self.value = try parseBlock(checksumString, Length)
    }

    public var description: String {
        get {
            return "Checksum{value=\(value)}"
        }
    }
}

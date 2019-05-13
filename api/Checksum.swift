
private let Length = 64

struct Checksum : CustomStringConvertible, Codable, Hashable {
    
    
    let value: [UInt8]

    init(value: [UInt8]) {
        value.CheckSize(Length)
        self.value = value
    }

    init(checksumString: String) throws {
        self.value = try parseBlock(checksumString, Length)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let checksumString = try container.decode(String.self)
        self.value = try parseBlock(checksumString, Length)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let checksumString = blockToString(value)
        try container.encode(checksumString)
    }

    public var description: String {
        get {
            return "Checksum{value=\(blockToString(value))}"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        var result = 0
        for byte in value {
            result = result &+ Int(byte)
            result = result &* ReasonablePrime
        }
        hasher.combine(result)
    }
}

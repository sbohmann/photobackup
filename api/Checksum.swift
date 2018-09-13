
private let Length = 64

struct Checksum : CustomStringConvertible, Codable {
    let value: [UInt8]

    init(value: [UInt8]) throws {
        try value.CheckSize(Length)
        self.value = value
    }

    init(checksumString: String) throws {
        self.value = try parseBlock(checksumString, Length)
    }
    
    enum CodingKeys : CodingKey {
        case value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let checksumString = try container.decode(String.self, forKey: .value)
        self.value = try parseBlock(checksumString, Length)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let checksumString = blockToString(value)
        try container.encode(checksumString, forKey: .value)
    }

    public var description: String {
        get {
            return "Checksum{value=\(blockToString(value))}"
        }
    }
}

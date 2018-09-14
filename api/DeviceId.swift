
struct DeviceId : CustomStringConvertible, Codable {
    private let Length = 16

    let value: [UInt8]

    init(value: [UInt8]) throws {
        value.CheckSize(Length)
        self.value = value
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

    var description: String {
        get {
            return "DeviceId{value=\(value)}"
        }
    }
}

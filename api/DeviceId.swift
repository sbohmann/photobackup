
struct DeviceId : CustomStringConvertible {
    private let Length = 16

    let value: [UInt8]

    init(value: [UInt8]) throws {
        try value.CheckSize(Length)
        self.value = value
    }

    var description: String {
        get {
            return "DeviceId{value=\(value)}"
        }
    }
}

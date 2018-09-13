
struct FileDescription : CustomStringConvertible {
    let checksum: Checksum
    let size: Int64
    let device: DeviceId
    let name: String
    let creationTime: Int64

    init(checksum: Checksum, size: Int64, device: DeviceId, name: String, creationTime: Int64) {
        self.checksum = checksum
        self.size = size
        self.device = device
        self.name = name
        self.creationTime = creationTime
    }

    var description: String {
        get {
            return "FileDescription{checksum=\(checksum), size=\(size), device=\(device), name='\(name)', creationTime=\(creationTime)}"
        }
    }
}

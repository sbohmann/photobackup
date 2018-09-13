
public class FilePresent: CustomStringConvertible {
    static let Yes = "6c34e454bfb6ced8"
    static let No = "367011a20b690e6a"

    let isPresent: Bool
    let confirmation: String
    let checksum: Checksum
    let trivialChecksum: Int

    init(isPresent: Bool, confirmation: String, checksum: Checksum, trivialChecksum: Int) {
        self.isPresent = isPresent
        self.confirmation = confirmation
        self.checksum = checksum
        self.trivialChecksum = trivialChecksum
    }

    public var description: String {
        get {
            return "FilePresent{isPresent=\(isPresent), confirmation='\(confirmation)', checksum=\(checksum), trivialChecksum=\(trivialChecksum)}"
        }
    }
}

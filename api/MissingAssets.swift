
import Foundation

struct MissingAssets : Codable {
    let missingAssetChecksums: [Checksum]
    
    public var description: String {
        get {
            return "MissingAssets{missingAssetChecksums=\(missingAssetChecksums)}";
        }
    }
}

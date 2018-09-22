
import Foundation
import Photos

struct Resource : CustomStringConvertible {
    let checksum: [UInt8]
    let rawResourceDescription: String
    let localAssetId: String
    let fileName: String
    let fileSize: Int64?
    let creationDate: Date?
    
    var description: String {
        get {
            let hexChecksum = blockToString(checksum)
            return "Resource{checksum=\(hexChecksum), rawResource=\(rawResourceDescription)"
        }
    }
}

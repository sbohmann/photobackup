
import Foundation
import Photos

struct Resource : CustomStringConvertible {
    let checksum: [UInt8]
    let rawResource: PHAssetResource
    let fileName: String?
    let fileSize: Int64?
    let creationDate: Date?
    
    var description: String {
        get {
            let hexChecksum = blockToString(checksum)
            return "Resource{checksum=\(hexChecksum), rawResource=\(rawResource)"
        }
    }
}

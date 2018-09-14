
import Foundation
import Photos

struct Asset : CustomStringConvertible {
    let name: String
    let creationDate: Date?
    let resources: [Resource]
    let rawAsset: PHAsset
    
    var description: String {
        get {
            return "Asset{resources=\(resources), rawAsset=\(rawAsset)"
        }
    }
}

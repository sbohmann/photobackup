
import Foundation
import Photos

struct Asset : CustomStringConvertible {
    let resources: [Resource]
    let rawAsset: PHAsset
    
    var description: String {
        get {
            return "Asset{resources=\(resources), rawAsset=\(rawAsset)"
        }
    }
}

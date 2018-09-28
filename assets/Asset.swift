
import Foundation
import Photos

struct Asset : CustomStringConvertible {
    let name: String
    let creationDate: Date?
    let resources: [Resource]
    
    var description: String {
        get {
            return "Asset{resources=\(resources), creationDate=\(creationDate?.description ?? "nil")}"
        }
    }
}

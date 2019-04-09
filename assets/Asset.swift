
import Foundation
import Photos

struct Asset : CustomStringConvertible, Codable {
    let name: String
    let creationDate: Date?
    let modificationDate: Date?
    let resources: [Resource]
    
    var description: String {
        get {
            return "Asset{resources=\(resources), creationDate=\(creationDate?.description ?? "nil")}"
        }
    }
}

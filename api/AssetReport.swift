
import Foundation

struct AssetReport : CustomStringConvertible, Encodable {
    let descriptions: [AssetDescription]
    
    public var description: String {
        get{
            return "AssetReport{descriptions=\(descriptions)}"
        }
    }
}

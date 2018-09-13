
import Foundation

struct AssetReport : CustomStringConvertible, Encodable {
    let descriptions: [ImageDescription]
    
    public var description: String {
        get{
            return "AssetReport{descriptions=\(descriptions)}"
        }
    }
}

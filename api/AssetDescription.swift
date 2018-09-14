
struct AssetDescription : CustomStringConvertible, Codable {
    // TODO location information from PHAsset
    // TODO creation timestamp, name, tags, &c.
    
    let name: String
    let creationDateMs: Int64?
    let resourceDescriptions: [ResourceDescription]
    
    var description: String {
        get {
            return "ImageDescription{name='\(name)',createDateMs=\(creationDateMs?.description ?? "undefined"), resourceDescriptions=\(resourceDescriptions)}"
        }
    }
}

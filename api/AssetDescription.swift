
struct AssetDescription : CustomStringConvertible, Codable {
    // TODO location information from PHAsset
    // TODO creation timestamp, name, tags, &c.
    
    let name: String
    let creationDateMs: Int64?
    let modificationDateMs: Int64?
    let resourceDescriptions: [ResourceDescription]
    
    var description: String {
        get {
            return "ImageDescription{name='\(name)', creationDateMs=\(creationDateMs?.description ?? "undefined"), modificationDateMs=\(modificationDateMs?.description ?? "undefined"), resourceDescriptions=\(resourceDescriptions)}"
        }
    }
}

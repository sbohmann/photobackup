
struct ImageDescription : CustomStringConvertible, Encodable {
    // TODO location information from PHAsset
    // TODO creation timestamp, name, tags, &c.
    
    let name: String
    
    var description: String {
        get {
            return "ImageDescription{name=\(name)}"
        }
    }
}

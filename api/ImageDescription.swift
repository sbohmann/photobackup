
struct ImageDescription : CustomStringConvertible, Encodable {
    // TODO location information from PHAsset
    // TODO creation timestamp, name, tags, &c.
    
    var description: String {
        get {
            return "ImageDescription{}"
        }
    }
}

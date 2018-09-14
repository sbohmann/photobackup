
struct ResourceDescription : CustomStringConvertible, Codable {
    let checksum: Checksum
    let size: Int64?
    let name: String?
    let creationDateMs: Int64?

    var description: String {
        get {
            return "FileDescription{checksum=\(checksum), size=\(size?.description ?? "undefined"), name='\(name ?? "")', creationDateMs=\(creationDateMs?.description ?? "undefined")}"
        }
    }
}

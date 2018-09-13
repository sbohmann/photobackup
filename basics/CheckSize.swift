
import Foundation

extension Collection {
    func CheckSize(_ size: Int) throws {
        if (count != size) {
            throw InvalidArgument("count [\(count)] != size [\(size)]")
        }
    }
}

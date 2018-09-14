
import Foundation

extension Collection {
    func CheckSize(_ size: Int) {
        if (count != size) {
            fatalError("count [\(count)] != size [\(size)]")
        }
    }
}

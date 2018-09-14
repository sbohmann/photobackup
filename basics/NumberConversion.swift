
import Foundation

func clongToINt64(_ value: CLong?) -> Int64? {
    if let value = value {
        return Int64(value)
    } else {
        return nil
    }
}

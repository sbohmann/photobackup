
import Foundation

class ChecksumCollector {
    private var state = CC_SHA512_CTX()
    private var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    
    init() {
        CC_SHA512_Init(&state)
    }
    
    var result: [UInt8] {
        get {
            return digest
        }
    }
    
    func handleData(data: Data) {
        NSLog("data size: %d", data.count)
        _ = data.withUnsafeBytes { pointer in CC_SHA512_Update(&state, pointer, CC_LONG(data.count)) }
    }
    
    func handleCompletion(error: Error?) {
        if let error = error {
            NSLog("Error: $@", error.localizedDescription)
        } else {
            NSLog("success :D")
            CC_SHA512_Final(&digest, &state)
            NSLog("%@", digest.map({ String(format: "%02hhx", $0) }).joined(separator: ""))
        }
    }
}

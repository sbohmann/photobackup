
import Foundation

class ChecksumCollector {
    private let resultHandler: ([UInt8]?) -> ()
    private var state = CC_SHA512_CTX()
    private var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    
    init(resultHandler: @escaping ([UInt8]?) -> ()) {
        self.resultHandler = resultHandler
        CC_SHA512_Init(&state)
    }
    
    var result: [UInt8] {
        get {
            return digest
        }
    }
    
    func handleData(data: Data) {
        _ = data.withUnsafeBytes{ pointer in CC_SHA512_Update(&state, pointer.baseAddress, CC_LONG(data.count)) }
    }
    
    func handleCompletion(error: Error?) {
        if let error = error {
            // TODO handle error
            NSLog("Error: %@", error.localizedDescription)
            self.resultHandler(nil)
        } else {
            CC_SHA512_Final(&digest, &state)
            self.resultHandler(self.digest)
        }
    }
}

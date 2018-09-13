
import Foundation

class ChecksumCollector {
    private let resultHandler: ([UInt8]) -> ()
    private var state = CC_SHA512_CTX()
    private var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    private let file: FileHandle
    
    init(resultHandler: @escaping ([UInt8]) -> ()) {
        self.resultHandler = resultHandler
        CC_SHA512_Init(&state)
        let path = "/tmp/\(arc4random()).jpg"
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        file = FileHandle(forWritingAtPath: path)!
    }
    
    var result: [UInt8] {
        get {
            return digest
        }
    }
    
    func handleData(data: Data) {
        _ = data.withUnsafeBytes { pointer in CC_SHA512_Update(&state, pointer, CC_LONG(data.count)) }
        file.write(data)
    }
    
    func handleCompletion(error: Error?) {
        if let error = error {
            // TODO handle error
            NSLog("Error: $@", error.localizedDescription)
        } else {
            CC_SHA512_Final(&digest, &state)
            DispatchQueue.main.async {
                self.resultHandler(self.digest)
            }
        }
        file.closeFile()
    }
}


import Foundation
import Photos

class ResourceCollector {
    private let asset: PHAsset
    private let resources: [PHAssetResource]
    private let resultHandler: (ResourceCollector) -> ()
    
    var resourcesForAsset = [Resource]()
    var skippedResources = 0
    
    private let queue: DispatchQueue
    
    init(_ asset: PHAsset, _ resources: [PHAssetResource], resultHandler: @escaping (ResourceCollector) -> ()) {
        self.asset = asset
        self.resources = resources
        self.resultHandler = resultHandler
        queue = DispatchQueue(label: "ResourceCollector for asset \(asset.localIdentifier)")
    }
    
    func run() {
        for resource in resources {
            let fileName = resource.responds(to: Selector("originalFilename"))
                ? resource.value(forKey: "originalFilename") as? String
                : nil
            
            let fileSize = resource.responds(to: Selector("fileSize"))
                ? resource.value(forKey: "fileSize") as? CLong
                : nil
            
            self.queue.async {
                let collector = ChecksumCollector() { checksum in
                    self.queue.sync {
                        if let checksum = checksum {
                            self.resourcesForAsset.append(Resource(checksum: checksum, rawResource: resource, fileName: fileName, fileSize: clongToInt64(fileSize), creationDate: self.asset.creationDate))
                        } else {
                            self.skippedResources += 1
                        }
                        if self.resourcesForAsset.count + self.skippedResources == self.resources.count {
                            self.resultHandler(self)
                        }
                    }
                }
                PHAssetResourceManager.default().requestData(
                    for: resource,
                    options: nil,
                    dataReceivedHandler: collector.handleData,
                    completionHandler: collector.handleCompletion)
            }
        }
    }
}

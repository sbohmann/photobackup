
import Foundation
import Photos

class ResourceCollector {
    private let asset: PHAsset
    private let resources: [PHAssetResource]
    private let resultHandler: (ResourceCollector) -> ()
    
    var resourcesForAsset = [Resource]()
    var skippedResources = 0
    
    private let group: DispatchGroup
    
    init(_ asset: PHAsset, _ resources: [PHAssetResource], resultHandler: @escaping (ResourceCollector) -> ()) {
        self.asset = asset
        self.resources = resources
        self.resultHandler = resultHandler
        group = DispatchGroup()
    }
    
    func run() {
        for resource in resources {
            group.enter()
            
            let fileName = resource.originalFilename
            
            let fileSize = resource.responds(to: Selector("fileSize"))
                ? resource.value(forKey: "fileSize") as? CLong
                : nil
            
            let collector = ChecksumCollector() { checksum in
                if let checksum = checksum {
                    self.resourcesForAsset.append(Resource(checksum: checksum, rawResource: resource, fileName: fileName, fileSize: clongToInt64(fileSize), creationDate: self.asset.creationDate))
                } else {
                    self.skippedResources += 1
                }
                if self.resourcesForAsset.count + self.skippedResources == self.resources.count {
                    self.resultHandler(self)
                }
                self.group.leave()
            }
            
            let options = PHAssetResourceRequestOptions()
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: options,
                dataReceivedHandler: collector.handleData,
                completionHandler: collector.handleCompletion)
            
            group.wait()
        }
    }
}

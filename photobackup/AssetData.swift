
import Foundation
import Photos

class AssetData {
//    PHImageManager:
//
//    For images: requestImageDataForAsset
//
//    For videos: requestExportSessionForVideo
    
    class func handleAsset(_ asset: PHAsset) {
        NSLog("asset local identifier: %@", asset.localIdentifier)
        let resources = PHAssetResource.assetResources(for: asset)
        for resource in resources {
            NSLog("resource: %@", resource)
            
            let collector = ChecksumCollector()
            
            if resource.responds(to: Selector("originalFilename")) {
                let fileName = resource.value(forKey: "originalFilename") as? String
                NSLog("resource filename: %@", fileName ?? "<unknown>")
            }
            
            if resource.responds(to: Selector("fileSize")) {
                let fileSize = resource.value(forKey: "fileSize") as? CLong
                NSLog("resource fileSize: %d", fileSize ?? -1)
            }
            
            let dataRequestId = PHAssetResourceManager.default().requestData(
                for: resource,
                options: nil,
                dataReceivedHandler: collector.handleData,
                completionHandler: collector.handleCompletion)
            NSLog("data request ID: %d", dataRequestId)
        }
    }
}


import Foundation
import Photos

class AssetData {
//    PHImageManager:
//
//    For images: requestImageDataForAsset
//
//    For videos: requestExportSessionForVideo
    
    class func handleAsset(_ asset: PHAsset) {
        let resources = PHAssetResource.assetResources(for: asset)
        for resource in resources {
            let fileSize = resource.value(forKey: "fileSize") as? CLong
            NSLog("resource fileSize: %d", fileSize ?? -1)
            let dataRequestId = PHAssetResourceManager.default().requestData(for: resource, options: nil, dataReceivedHandler: handleData, completionHandler: handleCompletion)
        }
    }

    private class func handleData(data: Data) {
        NSLog("data size: %d", data.count)
    }
    
    private class func handleCompletion(error: Error?) {
        if let error = error {
            NSLog("Error: $@", error.localizedDescription)
        }
    }
}

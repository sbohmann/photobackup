
import Foundation
import Photos

class AssetCollector {
    private let resultHandler: ([Asset]) -> ()
    private var assets = [Asset]()
    private var rawAssets: PHFetchResult<PHAsset>!
    
    static func run(resultHandler: @escaping ([Asset]) -> ()) {
        PHPhotoLibrary.requestAuthorization { status in
            AssetCollector(resultHandler).runIfAuthorized(status: status)
        }
    }
    
    private init(_ resultHandler: @escaping ([Asset]) -> ()) {
        self.resultHandler = resultHandler
    }
    
    private func runIfAuthorized(status: PHAuthorizationStatus) {
        if status == .authorized {
            self.runWithAuthorization()
        } else {
            NSLog("authorization status: %@", status.rawValue)
        }
    }
    
    private func runWithAuthorization() {
        rawAssets = PHAsset.fetchAssets(with: nil)
        NSLog("count: %d", rawAssets.count)
        rawAssets.enumerateObjects { (asset, count, boolPointer) in
            self.handleRawAsset(asset)
        }
    }
    
    private func handleRawAsset(_ asset: PHAsset) {
        NSLog("asset local identifier: %@", asset.localIdentifier)
        let resources = PHAssetResource.assetResources(for: asset)
        var resourcesForAsset = [Resource]()
        for resource in resources {
            let fileName = resource.responds(to: Selector("originalFilename"))
                ? resource.value(forKey: "originalFilename") as? String
                : nil
            
            let fileSize = resource.responds(to: Selector("fileSize"))
                ? resource.value(forKey: "fileSize") as? CLong
                : nil
            
            let collector = ChecksumCollector() { checksum in
                resourcesForAsset.append(Resource(checksum: checksum, rawResource: resource, fileName: fileName, fileSize: clongToINt64(fileSize), creationDate: asset.creationDate))
                if (resourcesForAsset.count == resources.count) {
                    self.addAsset(Asset(name: asset.localIdentifier, creationDate: asset.creationDate, resources: resourcesForAsset, rawAsset: asset))
                }
            }
            
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: nil,
                dataReceivedHandler: collector.handleData,
                completionHandler: collector.handleCompletion)
        }
    }
    
    private func addAsset(_ asset: Asset) {
        assets.append(asset)
        if (assets.count == rawAssets.count) {
            resultHandler(assets)
        }
    }
}

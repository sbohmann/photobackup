
import Foundation
import Photos

class AssetCollector {
    private let resultHandler: ([Asset]) -> ()
    private var statusHandler: (String, Float?) -> ()
    private var assets = [Asset]()
    private var assetCount = 0
    
    static func run(resultHandler: @escaping ([Asset]) -> (), statusHandler: @escaping (String, Float?) -> ()) {
        PHPhotoLibrary.requestAuthorization { status in
            AssetCollector(resultHandler, statusHandler).runIfAuthorized(status: status)
        }
    }
    
    private init(_ resultHandler: @escaping ([Asset]) -> (), _ statusHandler: @escaping (String, Float?) -> ()) {
        self.resultHandler = resultHandler
        self.statusHandler = statusHandler
    }
    
    private func runIfAuthorized(status: PHAuthorizationStatus) {
        if status == .authorized {
            self.runWithAuthorization()
        } else {
            NSLog("authorization status: %@", status.rawValue)
        }
    }
    
    private func runWithAuthorization() {
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        var fetchResults = [PHFetchResult<PHAsset>]()
        
        collections.enumerateObjects {collection, count, pointer in
            NSLog("Collections name: %@, type: %d/%d", collection.description, collection.assetCollectionType.rawValue, collection.assetCollectionSubtype.rawValue)
            let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            NSLog("count: %d", fetchResult.count)
            self.assetCount += fetchResult.count
            fetchResults.append(fetchResult)
        }
        
        for fetchResult in fetchResults {
            fetchResult.enumerateObjects { (asset, count, boolPointer) in
                self.handleRawAsset(asset)
            }
        }
    }
    
    private func handleRawAsset(_ asset: PHAsset) {
        let resources = PHAssetResource.assetResources(for: asset)
        if (resources.isEmpty) {
            assetCount -= 1
            reportIfFinished()
            return
        }
        var resourcesForAsset = [Resource]()
        var skippedResources = 0
        for resource in resources {
            let fileName = resource.responds(to: Selector("originalFilename"))
                ? resource.value(forKey: "originalFilename") as? String
                : nil
            
            let fileSize = resource.responds(to: Selector("fileSize"))
                ? resource.value(forKey: "fileSize") as? CLong
                : nil
            
            let collector = ChecksumCollector() { checksum in
                if let checksum = checksum {
                    resourcesForAsset.append(Resource(checksum: checksum, rawResource: resource, fileName: fileName, fileSize: clongToINt64(fileSize), creationDate: asset.creationDate))
                } else {
                    skippedResources += 1
                }
                if resourcesForAsset.count + skippedResources == resources.count {
                    if resourcesForAsset.count > 0 {
                        self.addAsset(Asset(name: asset.localIdentifier, creationDate: asset.creationDate, resources: resourcesForAsset, rawAsset: asset))
                    } else {
                        self.assetCount -= 1
                        self.reportIfFinished()
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
    
    private func addAsset(_ asset: Asset) {
        assets.append(asset)
        reportIfFinished()
    }
    
    private func reportIfFinished() {
        let message = "collected \(assets.count) out of \(assetCount) assets"
        DispatchQueue.main.async {
            self.statusHandler(message, self.assetCount > 0 ? Float(self.assets.count) / Float(self.assetCount) : 0.0)
        }
        if (assets.count == assetCount) {
            DispatchQueue.main.async {
                self.resultHandler(self.assets)
            }
        }
    }
}

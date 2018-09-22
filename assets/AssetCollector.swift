
import Foundation
import Photos

class AssetCollector {
    private let resultHandler: ([Asset]) -> ()
    private var statusHandler: (String, Float?) -> ()
    private var assets = [Asset]()
    private var initialAssetCount = 0
    private var assetCount = 0
    private var assetsWithoutResources = 0
    private var assetsWithSkippedResources = 0
    private var rawAssets = [PHAsset]()
    private var nextRawAssetIndex = 0
    
    private let queue = DispatchQueue(label: "AssetCollector")
    
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
            queue.async {
                self.runWithAuthorization()
            }
        } else {
            NSLog("authorization status: %@", status.rawValue)
        }
    }
    
    private func runWithAuthorization() {
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.fetchLimit = Int.max
        options.includeHiddenAssets = true
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options)
        var fetchResults = [PHFetchResult<PHAsset>]()
        
        collections.enumerateObjects {collection, count, pointer in
            NSLog("Collections name: %@, type: %d/%d", collection.description, collection.assetCollectionType.rawValue, collection.assetCollectionSubtype.rawValue)
            let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
            NSLog("count: %d", fetchResult.count)
            self.assetCount += fetchResult.count
            fetchResults.append(fetchResult)
        }
        
        self.initialAssetCount = assetCount
        
        for fetchResult in fetchResults {
            fetchResult.enumerateObjects { (asset, count, boolPointer) in
                self.rawAssets.append(asset)
            }
        }
        
        enqueueNextRawAsset()
    }
    
    private func enqueueNextRawAsset() {
        if nextRawAssetIndex < rawAssets.count {
            let asset = self.rawAssets[self.nextRawAssetIndex]
            nextRawAssetIndex += 1
            queue.async {
                self.handleRawAsset(asset)
            }
        }
    }
    
    private func handleRawAsset(_ asset: PHAsset) {
        let resources = PHAssetResource.assetResources(for: asset)
        if (resources.isEmpty) {
            assetCount -= 1
            assetsWithoutResources += 1
            reportIfFinished()
            enqueueNextRawAsset()
        } else {
            let resourceCollector = ResourceCollector(asset, resources) { result in
                self.queue.async {
                    if (result.skippedResources > 0) {
                        self.assetsWithSkippedResources += 1
                    }
                    if result.resourcesForAsset.count > 0 {
                        self.addAsset(Asset(name: asset.localIdentifier, creationDate: asset.creationDate, resources: result.resourcesForAsset, rawAsset: asset))
                    } else {
                        self.assetCount -= 1
                        self.reportIfFinished()
                    }
                    self.enqueueNextRawAsset()
                }
            }
            resourceCollector.run()
        }
    }
    
    private func addAsset(_ asset: Asset) {
        assets.append(asset)
        reportIfFinished()
    }
    
    private func reportIfFinished() {
        let message = "collected \(assets.count) out of\n\(initialAssetCount) assets\n\(assetsWithoutResources) empty assets\n\(assetsWithSkippedResources) assets with skipped resources"
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

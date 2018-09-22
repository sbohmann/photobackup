
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
    
    private let group = DispatchGroup()
    
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
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.fetchLimit = Int.max
        options.includeHiddenAssets = true
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options)
        
        collections.enumerateObjects { collection, count, pointer in
            NSLog("Collections name: %@, type: %d/%d", collection.description, collection.assetCollectionType.rawValue, collection.assetCollectionSubtype.rawValue)
            let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
            NSLog("count: %d", fetchResult.count)
            self.assetCount += fetchResult.count
            self.initialAssetCount = self.assetCount
            fetchResult.enumerateObjects { (asset, count, boolPointer) in
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
        } else {
            group.enter()
            
            let resourceCollector = ResourceCollector(asset, resources) { result in
                if result.skippedResources > 0 {
                    self.assetsWithSkippedResources += 1
                }
                if result.resourcesForAsset.count > 0 {
                    self.addAsset(Asset(name: asset.localIdentifier, creationDate: asset.creationDate, resources: result.resourcesForAsset, rawAsset: asset))
                } else {
                    self.assetCount -= 1
                    self.reportIfFinished()
                }
                self.group.leave()
            }
            resourceCollector.run()
            
            self.group.wait()
        }
    }
    
    private func addAsset(_ asset: Asset) {
        assets.append(asset)
        reportIfFinished()
    }
    
    private func reportIfFinished() {
        let message = "collected assets: \(assets.count)\nout of \(initialAssetCount)\nempty assets: \(assetsWithoutResources)\nassets with skipped resources: \(assetsWithSkippedResources)"
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

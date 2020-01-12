
import Foundation
import Photos
import CoreData

class AssetCollector {
    private let persistence: Persistence
    
    private let resultHandler: ([Asset]) -> ()
    private var statusHandler: (String, Float?) -> ()
    private var assets = [Asset]()
    private var initialAssetCount = 0
    private var assetCount = 0
    private var resourceCount = 0
    private var assetsWithoutResources = 0
    private var assetsWithSkippedResources = 0
    private var bursts = Dictionary<String,Int>()
    
    private let group = DispatchGroup()
    
    private init(_ resultHandler: @escaping ([Asset]) -> (),
                 _ statusHandler: @escaping (String, Float?) -> (),
                 _ persistence: Persistence) {
        self.resultHandler = resultHandler
        self.statusHandler = statusHandler
        self.persistence = persistence
    }
    
    static func run(resultHandler: @escaping ([Asset]) -> (),
                    statusHandler: @escaping (String, Float?) -> (),
                    persistence: Persistence) {
        PHPhotoLibrary.requestAuthorization { status in
            AssetCollector(resultHandler, statusHandler, persistence)
                .runIfAuthorized(status: status)
        }
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
                    
        let request: NSFetchRequest<KnownAsset> = KnownAsset.fetchRequest()
        
        var knownAssetsForName = Dictionary<String,[Asset]>()
        do {
            let knownAssets = try self.persistence.persistentContainer.viewContext.fetch(request)
            
//                for knownAsset in knownAssets {
//                    self.persistence.persistentContainer.viewContext.delete(knownAsset)
//                }
//                self.persistence.saveContext()
//                NSLog("Deleted all data")
//                return
            
            for knownAsset in knownAssets {
                if let name = knownAsset.name, let serializedAsset = knownAsset.asset {
                    let asset = try JSONDecoder().decode(Asset.self, from: serializedAsset)
                    if asset.name != name {
                        NSLog("name mismatch - \(name) vs. \(asset.name)")
                    }
                    var assetsForName = knownAssetsForName[name] ?? []
                    assetsForName.append(asset)
                    knownAssetsForName[name] = assetsForName
                }
            }
        } catch {
            NSLog("Failed to fetch assets from core data - \(error)")
        }
        
        NSLog("Enumerating collections")
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options)
        collections.enumerateObjects { collection, count, pointer in
            NSLog("Collections name: %@, type: %d/%d", collection.description, collection.assetCollectionType.rawValue, collection.assetCollectionSubtype.rawValue)
            let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
            NSLog("count: %d", fetchResult.count)
            self.assetCount += fetchResult.count
            self.initialAssetCount = self.assetCount
            
            NSLog("Enumerating assets")
            var timeHandlingRawAssets: Int64 = 0
            let beforeEnumeration = DispatchTime.now()
            fetchResult.enumerateObjects { (asset, count, boolPointer) in
                let beforeHandleRawAsset = DispatchTime.now()
                self.handleRawAsset(asset, knownAssetsForName)
                self.handleBurstAssets(asset, knownAssetsForName)
                let afterHandleRawAsset = DispatchTime.now()
                let delta = afterHandleRawAsset.uptimeNanoseconds - beforeHandleRawAsset.uptimeNanoseconds
                timeHandlingRawAssets += Int64(delta)
            }
            
            let afterEnumeration = DispatchTime.now()
            let timeEnumerating = afterEnumeration.uptimeNanoseconds - beforeEnumeration.uptimeNanoseconds
            NSLog("time handling raw assets: %f", Double(timeHandlingRawAssets) / 1_000_000_000.0)
            NSLog("time enumerating:         %f", Double(timeEnumerating) / 1_000_000_000.0)
        }
    }
    
    private func handleBurstAssets(_ asset: PHAsset, _ knownAssetsForName: Dictionary<String,[Asset]>) {
        if asset.representsBurst {
            guard let burstId = asset.burstIdentifier else {
                NSLog("Encountered asssed representing burst without burst ID. local ID: \(asset.localIdentifier)")
                return
            }
            let options = PHFetchOptions()
            options.includeAllBurstAssets = true
            options.fetchLimit = Int.max
            options.includeHiddenAssets = true
            let fetchResult = PHAsset.fetchAssets(withBurstIdentifier: burstId, options: options)
            NSLog("Enumerating burst assets for burst ID \(asset.burstIdentifier ?? "<none>"), local ID \(asset.localIdentifier)")
            fetchResult.enumerateObjects { (burstAsset, count, boolPointer) in
                if burstAsset.localIdentifier != asset.localIdentifier {
                    NSLog("Handling burst asset with burst ID \(burstAsset.burstIdentifier ?? "<none>"), local ID \(burstAsset.localIdentifier)")
                    self.handleRawAsset(burstAsset, knownAssetsForName)
                } else {
                    NSLog("Asset with same burst ID enumerated while fetching with burst ID")
                }
            }
        }
    }
    
    private func handleRawAsset(_ asset: PHAsset, _ knownAssetsForName: Dictionary<String,[Asset]>) {
        var is_burst = false
        if let burstId = asset.burstIdentifier {
            var number = bursts[burstId] ?? 0
            number += 1
            bursts[burstId] = number
            NSLog("Encountered burst ID \(burstId), local ID \(asset.localIdentifier), number: \(number)")
            is_burst = true
        }
        
        if let modificationDate = asset.modificationDate ?? asset.creationDate {
            if let assetsForName = knownAssetsForName[asset.localIdentifier] {
                for knownAsset in assetsForName {
                    if knownAsset.modificationDate == modificationDate {
                        self.addAsset(knownAsset)
                        if (is_burst) {
                            NSLog("Returning")
                        }
                        return
                    }
                }
            }
        }
        
        NSLog("Processing asset \(asset.localIdentifier)")
        
        let resources = PHAssetResource.assetResources(for: asset)
        
        if (resources.isEmpty) {
            assetCount -= 1
            assetsWithoutResources += 1
            reportIfFinished()
        } else {
            group.enter()
            
            let resourceCollector = ResourceCollector(asset, resources) { result in
                NSLog("Handling \(result.resourcesForAsset.count) resources for asset \(asset.localIdentifier)")
                if result.skippedResources > 0 {
                    self.assetsWithSkippedResources += 1
                }
                if result.resourcesForAsset.count > 0 {
                    let newAsset = Asset(
                        name: asset.localIdentifier,
                        creationDate: asset.creationDate,
                        modificationDate: asset.modificationDate ?? asset.creationDate,
                        resources: result.resourcesForAsset)
                    
                    self.addAsset(newAsset)
                    
                    if let modificationDate = asset.modificationDate ?? asset.creationDate {
                        do {
                            let serializedAsset = try JSONEncoder().encode(newAsset)
                            let newKnownAsset = KnownAsset(context: self.persistence.persistentContainer.viewContext)
                            newKnownAsset.name = asset.localIdentifier
                            newKnownAsset.modificationDate = modificationDate.timeIntervalSince1970
                            newKnownAsset.asset = serializedAsset
                            if newKnownAsset.name != newAsset.name || newKnownAsset.name != asset.localIdentifier {
                                NSLog("Name mismatch - \(newKnownAsset.name ?? "none"), \(newAsset.name), \(asset.localIdentifier)")
                            }
                        } catch {
                            NSLog("Failed to save asset of name \(asset.localIdentifier) and modification date \(modificationDate) from core data - \(error)")
                        }
                    }
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
        resourceCount += asset.resources.count
        reportIfFinished()
    }
    
    private func reportIfFinished() {
        let message =
            "collected assets: \(assets.count)\n" +
            "out of \(initialAssetCount)\n" +
            "resources: \(resourceCount)\n" +
            "ratio: \(assets.count > 0 ? (Double(resourceCount) / Double(assets.count)).description : "-")\n" +
            "empty assets: \(assetsWithoutResources)\n" +
            "assets with skipped resources: \(assetsWithSkippedResources)"
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

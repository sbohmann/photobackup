
import Foundation
import Photos

class Core {
    func listPhotos() {
        PHPhotoLibrary.requestAuthorization { status in self.listPhotosIfAuthorized(status: status)}
    }
    
    func listPhotosIfAuthorized(status: PHAuthorizationStatus) {
        if status == .authorized {
            self.listPhotosWithAuthorization()
        } else {
            NSLog("authorization status: %@", status.rawValue)
        }
    }
    
    func listPhotosWithAuthorization() {
        let result = PHAsset.fetchAssets(with: nil)
        NSLog("count: %d", result.count)
        result.enumerateObjects { (asset, count, boolPointer) in
            NSLog("asset: %@, count: %d", asset, count)
            self.logSourceType(asset.sourceType)
            self.logMediaType(asset.mediaType)
            NSLog("size: %d x %d", asset.pixelWidth, asset.pixelHeight)
        }
    }
    
    func logSourceType(_ type: PHAssetSourceType) {
        switch type {
        case .typeUserLibrary:
            NSLog("user library")
        case .typeCloudShared:
            NSLog("cloud shared")
        case .typeiTunesSynced:
            NSLog("itunes synced")
        default:
            NSLog("unknown value: %d", type.rawValue)
        }
    }
    
    func logMediaType(_ type: PHAssetMediaType) {
        switch type {
        case .unknown:
            NSLog("unknown")
        case .image:
            NSLog("image")
        case .video:
            NSLog("video")
        case .audio:
            NSLog("audio")
        }
    }
}


import Foundation
import Photos

func sourceTypeToString(_ type: PHAssetSourceType) -> String {
    switch type {
    case .typeUserLibrary:
        return "user library"
    case .typeCloudShared:
        return "cloud shared"
    case .typeiTunesSynced:
        return "itunes synced"
    default:
        return "unknown value: \(type.rawValue)"
    }
}

func mediaTypeToString(_ type: PHAssetMediaType) -> String {
    switch type {
    case .image:
        return "image"
    case .video:
        return "video"
    case .audio:
        return "audio"
    default:
        return "unknown"
    }
}

func mediaSubtypeToString(_ subtype: PHAssetMediaSubtype) -> String {
    switch subtype {
    case .photoPanorama:
        return "photoPanorama"
    case .photoHDR:
        return "photoHDR"
    case .photoScreenshot:
        return "photoScreenshot"
    case .photoLive:
        return "photoLive"
    case .photoDepthEffect:
        return "photoDepthEffect"
    case .videoStreamed:
        return "videoStreamed"
    case .videoHighFrameRate:
        return "videoHighFrameRate"
    case .videoTimelapse:
        return "videoTimelapse"
    default:
        break
    }
    return "\(subtype.rawValue)"
}

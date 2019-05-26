
import Foundation
import Photos

class Core {
    let settings: Settings
    let statusHandler: (String, Float?) -> ()
    let persistence = Persistence()
    var token: String? = nil
    
    init(settings: Settings, statusHandler: @escaping (String, Float?) -> ()) {
        self.settings = settings
        self.statusHandler = statusHandler
    }
    
    func listAssets(resultHandler: @escaping ([Asset], MissingAssets) -> ()) {
        AssetCollector.run(
            resultHandler: { assets in
                NSLog("reporting %d assets", assets.count )
                
                self.persistence.saveContext()
                
                self.loginIfRequired {
                    self.sendReport(assets: assets) { missingAssets in
                        resultHandler(assets, missingAssets)
                    }
                }
            },
            statusHandler: statusHandler,
            persistence: persistence)
    }
    
    func sendReport(assets: [Asset], resultHandler: @escaping (MissingAssets) -> ()) {
        NSLog("on main thread before: %@", Thread.isMainThread ? "true" : "false")
        let url = URL(string: settings.protocolName + "://\(settings.host):\(settings.port)/asset-report")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        insertToken(&request)
        do {
            let descriptions: [AssetDescription] = assets.map { asset in
                let resourceDescriptions: [ResourceDescription] = asset.resources.map { resource in
                    return ResourceDescription(
                        checksum: Checksum(value: resource.checksum),
                        size: resource.fileSize,
                        name: resource.fileName,
                        creationDateMs: dateToMillisecondTimestamp(resource.creationDate))
                }
                return AssetDescription(
                    name: asset.name,
                    creationDateMs: dateToMillisecondTimestamp(asset.creationDate),
                    modificationDateMs: dateToMillisecondTimestamp(asset.modificationDate),
                    resourceDescriptions: resourceDescriptions)
            }
            let data = try JSONEncoder().encode(AssetReport(descriptions: descriptions))
            let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
                self.reportCompletion(data, response, error)
                do {
                    if let data = data {
                        let result = try JSONDecoder().decode(MissingAssets.self, from: data)
                        NSLog("%@", result.description)
                        NSLog("on main thread after: %@", Thread.isMainThread ? "true" : "false")
                        DispatchQueue.main.async {
                            resultHandler(result)
                        }
                    }
                } catch {
                    NSLog("Failed to decode data: %@", error.localizedDescription)
                }
            }
            task.resume()
        } catch {
            NSLog("Failed to encode data: %@", error.localizedDescription)
        }
    }
    
    func upload(resources: [Resource], numberOfResources: Int) {
        guard let resource = resources.first else {
            return
        }
        
        var rawResourceOption: PHAssetResource? = nil
        
        let options = PHAssetResourceRequestOptions()
        let rawAssets = PHAsset.fetchAssets(withLocalIdentifiers: [resource.localAssetId], options: nil)
        rawAssets.enumerateObjects { rawAsset, count, stop in
            PHAssetResource.assetResources(for: rawAsset).forEach { candidate in
                if candidate.originalFilename == resource.fileName {
                    if rawResourceOption == nil {
                        rawResourceOption = candidate
                    } else {
                        NSLog("Found competing asset resources of common name %@ for asset %@", resource.fileName, resource.localAssetId)
                    }
                }
            }
        }
        
        guard let rawResource = rawResourceOption else {
            NSLog("Found no asset resources of name %@ for asset %@", resource.fileName, resource.localAssetId)
            return
        }
        
        if numberOfResources > 0 {
            let resourcesFinished = numberOfResources - resources.count
            statusHandler("Uploading resource \(resourcesFinished + 1) / \(numberOfResources)", Float(resourcesFinished) / Float(numberOfResources))
        }
        
        let url = URL(string: settings.protocolName + "://\(settings.host):\(settings.port)/resource-upload/" + blockToString(resource.checksum))!
        
        var boundInputStream: InputStream?
        var boundOutputStream: OutputStream?
        Stream.getBoundStreams(withBufferSize: 1024 * 1024, inputStream: &boundInputStream, outputStream: &boundOutputStream)
        
        guard let inputStream = boundInputStream, let outputStream = boundOutputStream else {
            NSLog("%@ unable to create streams")
            self.startNextUpload(resources: resources, numberOfResources: numberOfResources)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-type")
        insertToken(&request)
        request.httpBodyStream = inputStream
        
//        let task = URLSession.shared.uploadTask(with: request, from: nil, completionHandler: { data, response, error in
//            self.reportCompletion(data, response, error)
//        })
        //let task = URLSession.shared.uploadTask(withStreamedRequest: request)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            NSLog("dataTask completed - data length: \(data?.count.description ?? "unknown")")
            self.reportCompletion(data, response, error)
            self.startNextUpload(resources: resources, numberOfResources: numberOfResources)
        })
        if let size = resource.fileSize {
            NSLog("size: %d", size)
        }
        task.resume()
        outputStream.open()
        
        let handleData = { (data: Data) in
            var part = data
            while part.count > 0 {
                let result = part.withUnsafeBytes({ bytes in outputStream.write(bytes, maxLength: part.count)})
//                NSLog("write result: %d", result)
                if (result < 0) {
                    NSLog("error writing to stream: %@", outputStream.streamError?.localizedDescription ?? "<unknown>")
                    outputStream.close()
                    // TODO report error
                    break
                }
//                NSLog("%d bytes written", result)
                if (result == part.count) {
                    break
                }
                part = part.advanced(by: result)
            }
        }
        
        let handleCompletion = { (error: Error?) in
            outputStream.close()
            if let error = error {
                NSLog("error reading resource [%@]: %@", resource.fileName, error.localizedDescription)
            } else {
                NSLog("Finished writing resource [%@], checksum: %@", resource.fileName, blockToString(resource.checksum))
            }
        }
        
        PHAssetResourceManager.default().requestData(
            for: rawResource,
            options: options,
            dataReceivedHandler: handleData,
            completionHandler: handleCompletion)
    }
    
    private func reportCompletion(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        DispatchQueue.main.async {
            NSLog("data length: %d", data?.count ?? 0)
            NSLog("response: %@", response?.description ?? "no response")
            NSLog("error: %@", error?.localizedDescription ?? "no error")
//            data?.withUnsafeBytes({ (pointer: UnsafePointer<CChar>) in
//                NSLog("%s", pointer)
//            })
        }
    }
    
    private func startNextUpload(resources: [Resource], numberOfResources: Int) {
        let rest = [Resource](resources[1...])
        if !rest.isEmpty {
            DispatchQueue.main.async {
                self.upload(resources: rest, numberOfResources: numberOfResources)
            }
        } else {
            DispatchQueue.main.async {
                // TODO report number of errors!!!
                self.statusHandler("Finished uploading resources.", 1.0)
            }
        }
    }
    
    private func insertToken(_ request: inout URLRequest) {
        if let token = token {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
    }
    
    private func loginIfRequired(_ then: @escaping (() -> ())) {
        if settings.tls, token == nil, let password = settings.password {
            login(password, then)
        } else {
            then()
        }
    }
    
    private func login(_ password: String, _ then: @escaping (() -> ())) {
        let url = URL(string: "https://\(settings.host):\(settings.port)/login/api")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-type")
        request.httpBody = password.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            NSLog("login completed - data length: \(data?.count.description ?? "unknown")")
            if let data = data {
                self.token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                then()
            }
        })
        task.resume()
    }
}

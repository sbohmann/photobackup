
import Foundation
import Photos

class Core {
    let statusHandler: (String, Float?) -> ()
    
    init(statusHandler: @escaping (String, Float?) -> ()) {
        self.statusHandler = statusHandler
    }
    
    func listAssets(resultHandler: @escaping ([Asset], MissingAssets) -> ()) {
        AssetCollector.run(
            resultHandler: { assets in
                NSLog("rporting %d assets", assets.count )

                self.sendReport(assets: assets) { missingAssets in
                    resultHandler(assets, missingAssets)
                }
            },
            statusHandler: statusHandler)
    }
    
    func sendReport(assets: [Asset], resultHandler: @escaping (MissingAssets) -> ()) {
        NSLog("on main thread before: %@", Thread.isMainThread ? "true" : "false")
        let url = URL(string: "http://10.0.0.39:8080/asset-report")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
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
                    } else {
                        NSLog("Failed to decode data")
                    }
                } catch {
                    NSLog("%@", error.localizedDescription)
                }
            }
            task.resume()
        } catch {
            NSLog("error: %@", error.localizedDescription)
        }
    }
    
    func upload(resources: [Resource], numberOfResources: Int) {
        guard let resource = resources.first else {
            return
        }
        
        if numberOfResources > 0 {
            let resourcesFinished = numberOfResources - resources.count
            statusHandler("Uploading resource \(resourcesFinished + 1) / \(numberOfResources)", Float(resourcesFinished) / Float(numberOfResources))
        }
        
        let url = URL(string: "http://10.0.0.39:8080/resource-upload/" + blockToString(resource.checksum))!
        
        var boundInputStream: InputStream?
        var boundOutputStream: OutputStream?
        Stream.getBoundStreams(withBufferSize: 1024 * 1024, inputStream: &boundInputStream, outputStream: &boundOutputStream)
        
        guard let inputStream = boundInputStream, let outputStream = boundOutputStream else {
            NSLog("%@ unable to create streams")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-type")
        request.httpBodyStream = inputStream
        
//        let task = URLSession.shared.uploadTask(with: request, from: nil, completionHandler: { data, response, error in
//            self.reportCompletion(data, response, error)
//        })
        //let task = URLSession.shared.uploadTask(withStreamedRequest: request)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            self.reportCompletion(data, response, error)
        })
        if let size = resource.fileSize {
            NSLog("size: %d", size)
        }
        task.resume()
        outputStream.open()
        
        var error = false
        
        let handleData = { (data: Data) in
            var part = data
            if error {
                return
            }
            while part.count > 0 {
                let result = part.withUnsafeBytes({ bytes in outputStream.write(bytes, maxLength: part.count)})
                NSLog("write result: %d", result)
                if (result < 0) {
                    NSLog("error writing to stream: %@", outputStream.streamError?.localizedDescription ?? "<unknown>")
                    outputStream.close()
                    // TODO report error
                    error = true
                    break
                }
                NSLog("%d bytes written", result)
                if (result == part.count) {
                    break
                }
                part = part.advanced(by: result)
            }
        }
        
        let handleCompletion = { (error: Error?) in
            outputStream.close()
            if let error = error {
                NSLog("error reading resource [%@]: %@", resource.fileName?.description ?? "", error.localizedDescription)
            } else {
                NSLog("Finished writing resource [%@]", resource.fileName?.description ?? "")
            }
            // TODO move starting next upload to task completion or, even better, just limit parallel uploads
            // task completion is risky because it doesn't always happen... (e.g. in the face of some exceptions on the server
            // continuing is really important because this is a photo backup app.
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
        
        PHAssetResourceManager.default().requestData(
            for: resource.rawResource,
            options: nil,
            dataReceivedHandler: handleData,
            completionHandler: handleCompletion)
        
//        if let data = "Hallo".data(using: .utf8) {
//            data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> () in
//                outputStream.write(pointer, maxLength: data.count)
//                outputStream.close()
//            }
//        }
    }
    
    func reportCompletion(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        DispatchQueue.main.async {
            NSLog("%d", data?.count ?? 0)
            NSLog("%@", response?.description ?? "no response")
            NSLog("%@", error?.localizedDescription ?? "no error")
            data?.withUnsafeBytes({ (pointer: UnsafePointer<CChar>) in
                NSLog("%s", pointer)
            })
        }
    }
}


import Foundation

class Core {
    func listPhotos() {
        AssetCollector.run { assets in
            assets.forEach { asset in
                NSLog("asset %@", asset.description)
            }
            
            self.sendReport(assets)
        }
    }
    
    func sendReport(_ assets: [Asset]) {
        let url = URL(string: "http://127.0.0.1:8080/image-upload/asset-report")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        do {
            let data = try JSONEncoder().encode(AssetReport(descriptions: [ImageDescription(name: "hello")]))
            let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
                NSLog("%d", data?.count ?? -1)
                NSLog("%@", response?.description ?? "no response")
                NSLog("%@", error?.localizedDescription ?? "no error")
                data?.withUnsafeBytes({ (pointer: UnsafePointer<CChar>) in
                    NSLog("%s", pointer)
                })
                do {
                    if let data = data {
                        let result = try JSONDecoder().decode(MissingAssets.self, from: data)
                        NSLog("%@", result.description)
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
    
    func uploadResource(_ resource: Resource) {
        let url = URL(string: "http://127.0.0.1:8080/resourceUpload")!
        
        var boundInputStream: InputStream?
        var boundOutputStream: OutputStream?
        Stream.getBoundStreams(withBufferSize: 1024 * 1024, inputStream: &boundInputStream, outputStream: &boundOutputStream)
        
        guard let inputStream = boundInputStream, let outputStream = boundOutputStream else {
            // TODO handle error
            return
        }
        
        var request = URLRequest(url: url)
        request.httpBodyStream = inputStream
        
        let task = URLSession.shared.uploadTask(withStreamedRequest: request)
        
        // TODO
    }
}

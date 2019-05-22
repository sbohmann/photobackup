
import Foundation

class Settings {
    var host: String = ""
    var port = 8080
    var tls = false
    var password: String?
    var credentialStorage: URLCredentialStorage?
    
    var protocolName: String {
        get {
            return tls ? "https" : "http"
        }
    }
    
    var save: (() -> ())?
    
    func update() {
        if tls, let password = password {
            setCredentialStorage()
        } else {
            credentialStorage = nil
        }
    }
    
    private func setCredentialStorage() {
        let credential = URLCredential(user: "photobackup", password: "b:", persistence: URLCredential.Persistence.forSession)
        let protectionSpace = URLProtectionSpace(host: host, port: port, protocol: "https", realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPDigest)
        URLCredentialStorage.shared.setDefaultCredential(credential, for: protectionSpace)
    }
}

class StoredSettings {
    private static let HostKey = "host"
    private static let PortKey = "port"
    private static let TlsKey = "tls"
    
    static let instance = load()
    
    private static func load() -> Settings {
        let result = Settings()
        let def = UserDefaults.standard
        let hostOption = def.string(forKey: HostKey)
        if let host = hostOption {
            result.host = host
        }
        let port = def.integer(forKey: PortKey)
        if port != 0 {
            result.port = port
        }
        result.tls = def.bool(forKey: TlsKey)
        result.save = {
            save(result)
        }
        result.update()
        return result
    }
    
    private static func save(_ settings: Settings) {
        //result.update()
        let def = UserDefaults.standard
        def.set(settings.host, forKey: HostKey)
        def.set(settings.port, forKey: PortKey)
        def.set(settings.tls, forKey: TlsKey)
        def.synchronize()
    }
}

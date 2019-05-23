
import Foundation

class Settings {
    var host: String = ""
    var port = 8080
    var tls = false
    var password: String?
    
    var protocolName: String {
        get {
            return tls ? "https" : "http"
        }
    }
    
    var save: (() -> ())?
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


import Foundation

class Settings {
    var host: String = ""
    var port = 8080
    var save: (() -> ())?
}

class StoredSettings {
    static let HostKey = "host"
    static let PortKey = "port"
    
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
        result.save = {
            save(result)
        }
        return result
    }
    
    private static func save(_ settings: Settings) {
        let def = UserDefaults.standard
        def.set(settings.host, forKey: HostKey)
        def.set(settings.port, forKey: PortKey)
        def.synchronize()
    }
}

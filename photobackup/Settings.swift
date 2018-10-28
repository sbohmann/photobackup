
import Foundation

class Settings {
    var host: String = ""
    var port = 8080
}

class SettingsSingletonFactory {
    static let instance = Settings()
}

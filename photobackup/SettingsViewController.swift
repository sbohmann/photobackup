
import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var tlsSwitch: UISwitch!
    
    let settings = StoredSettings.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hostTextField.text = settings.host
        portTextField.text = settings.port.description
        tlsSwitch.isOn = settings.tls
        passwordTextField.text = settings.password
    }
    
    @IBAction func change(_ sender: Any) {
        if let rawText = hostTextField.text, let rawPort = portTextField.text, let rawPassword = passwordTextField.text {
            setRawHostAndPort(rawText, rawPort, tlsSwitch.isOn, rawPassword)
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func setRawHostAndPort(_ host: String, _ port: String, _ tls: Bool, _ rawPassword: String) {
        let trimmedHost = trimmed(host)
        let trimmedPort = trimmed(port)
        let password = trimmedAndNilIfEmpty(rawPassword)
        if !trimmedHost.isEmpty && !trimmedPort.isEmpty {
            setTrimmedHostNameAndPort(trimmedHost, trimmedPort, tls, password)
        }
    }
    
    private func trimmed(_ text: String) -> String {
        return text.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    private func trimmedAndNilIfEmpty(_ text: String) -> String? {
        let trimmedText = trimmed(text)
        return trimmedText.isEmpty ? nil : trimmedText
    }
    
    private func setTrimmedHostNameAndPort(_ host: String, _ portAsText: String, _ tls: Bool, _ password: String?) {
        if let port = Int(portAsText) {
            settings.host = host
            settings.port = port
            settings.tls = tls
            settings.password = password
            settings.save?()
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

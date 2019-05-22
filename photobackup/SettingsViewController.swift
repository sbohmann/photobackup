
import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var tlsSwitch: UISwitch!
    
    let settings = StoredSettings.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hostTextField.text = settings.host
        portTextField.text = settings.port.description
        tlsSwitch.isOn = settings.tls
    }
    
    @IBAction func change(_ sender: Any) {
        if let rawText = hostTextField.text, let rawPort = portTextField.text {
            setRawHostAndPort(rawText, rawPort, tlsSwitch.isOn)
        }
    }
    
    private func setRawHostAndPort(_ host: String, _ port: String, _ tls: Bool) {
        let trimmedHost = host
            .trimmingCharacters(in: CharacterSet.whitespaces)
        let trimmedPort = port
            .trimmingCharacters(in: CharacterSet.whitespaces)
        if !trimmedHost.isEmpty && !trimmedPort.isEmpty {
            setTrimmedHostNameAndPort(trimmedHost, trimmedPort, tls)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func setTrimmedHostNameAndPort(_ host: String, _ portAsText: String, _ tls: Bool) {
        if let port = Int(portAsText) {
            settings.host = host
            settings.port = port
            settings.tls = tls
            settings.save?()
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

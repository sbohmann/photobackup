
import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    
    let settings = StoredSettings.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hostTextField.text = settings.host
        portTextField.text = settings.port.description
    }
    
    @IBAction func change(_ sender: Any) {
        if let rawText = hostTextField.text, let rawPort = portTextField.text {
            setRawHostAndPort(rawText, rawPort)
        }
    }
    
    private func setRawHostAndPort(_ host: String, _ port: String) {
        let trimmedHost = host
            .trimmingCharacters(in: CharacterSet.whitespaces)
        let trimmedPort = port
            .trimmingCharacters(in: CharacterSet.whitespaces)
        if !trimmedHost.isEmpty && !trimmedPort.isEmpty {
            setTrimmedHostNameAndPort(trimmedHost, trimmedPort)
        }
        dismiss(animated: true, completion: nil)
    }
    func setTrimmedHostNameAndPort(_ host: String, _ portAsText: String) {
        if let port = Int(portAsText) {
            settings.host = host
            settings.port = port
            settings.save?()
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

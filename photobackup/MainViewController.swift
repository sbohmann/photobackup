
import UIKit

class MainViewController: UIViewController {
    var running = false
    @IBOutlet weak var mainButton: UIButton!
    @IBOutlet weak var textbox: UITextView!
    @IBOutlet weak var progressbar: UIProgressView!
    var core: Core!
    
    let settings: Settings = StoredSettings.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        core = Core(
            settings: settings,
            statusHandler: { status, progress in
                self.reportStatus(status, progress)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func mainButtonAction(_ sender: Any) {
        NSLog("Main action triggered")
        mainButton.isEnabled = false
        running = true
        core.listAssets { assets, missingAssets in
            let missingAssetChecksums = Set<Checksum>(missingAssets.missingAssetChecksums)
            var filteredResources = [Resource]()
            if missingAssets.missingAssetChecksums.isEmpty {
                self.textbox.text = "No missing resources reported"
                self.progressbar.progress = 1.0
            }
            assets.forEach { asset in
                filteredResources.append(
                    contentsOf: asset
                        .resources
                        .filter({ resource in missingAssetChecksums.contains(Checksum(value: resource.checksum)) }))
            }
            self.core.upload(resources: filteredResources, numberOfResources: filteredResources.count)
        }
    }
    
    private func reportStatus(_ status: String, _ progress: Float?) {
        self.textbox.text = status
        if let progress = progress {
            self.progressbar.progress = progress
        }
    }
}

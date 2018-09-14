
import UIKit

class MainViewController: UIViewController {
    let core = Core();
    var running = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func mainButtonAction(_ sender: Any) {
        NSLog("Main action triggered")
        running = true
        core.listAssets { assets, missingAssets in
            let missingAssetChecksums = Set<Checksum>(missingAssets.missingAssetChecksums)
            var filteredResources = [Resource]()
            assets.forEach { asset in
                filteredResources.append(
                    contentsOf: asset
                        .resources
                        .filter({ resource in missingAssetChecksums.contains(Checksum(value: resource.checksum)) }))
            }
            self.core.upload(resources: filteredResources)
        }
    }
}

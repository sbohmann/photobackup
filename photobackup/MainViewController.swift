
import UIKit

class MainViewController: UIViewController {
    let core = Core();
    
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
        core.listPhotos()
    }
}

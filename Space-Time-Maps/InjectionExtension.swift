// https://medium.com/@robnorback/the-secret-to-1-second-compile-times-in-xcode-9de4ec8345a1
// HOT RELOAD VIA INJECTION :-)

import UIKit

extension UIViewController { //5
    
    #if DEBUG //1
    @objc func injected() { //2
    for subview in self.view.subviews { //3
        subview.removeFromSuperview()
    }
    
    viewDidLoad() //4
    }
    #endif
}

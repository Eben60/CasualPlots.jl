import Cocoa
import CoreGraphics

let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements)
if let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
    for info in windowInfoList {
        if let owner = info[kCGWindowOwnerName as String] as? String,
           let name = info[kCGWindowName as String] as? String,
           let windowID = info[kCGWindowNumber as String] as? Int {
            if owner == "Julia" && name == "Bonito App" {
                print("\(windowID)")
                exit(0)
            }
        }
    }
}
exit(1)

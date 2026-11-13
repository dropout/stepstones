import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // The master-detail layouts need more room than the template's default window.
    let minimumSize = NSSize(width: 1000, height: 640)
    self.minSize = minimumSize
    var windowFrame = self.frame
    windowFrame.size = NSSize(
      width: max(windowFrame.width, 1200), height: max(windowFrame.height, 760))
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

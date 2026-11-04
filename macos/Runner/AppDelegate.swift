import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var backgroundActivity: NSObjectProtocol?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    backgroundActivity = ProcessInfo.processInfo.beginActivity(
      options: .userInitiatedAllowingIdleSystemSleep,
      reason: "秒薪需要在后台继续计算收入"
    )
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "context_collector/macos_edit",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "perform",
            let commandName = call.arguments as? String,
            let command = EditCommand(rawValue: commandName) else {
        result(FlutterMethodNotImplemented)
        return
      }

      NSApp.sendAction(command.selector, to: nil, from: nil)
      result(nil)
    }

    super.awakeFromNib()
  }
}

private enum EditCommand: String {
  case undo
  case redo
  case cut
  case copy
  case paste
  case selectAll

  var selector: Selector {
    switch self {
    case .undo:
      return NSSelectorFromString("undo:")
    case .redo:
      return NSSelectorFromString("redo:")
    case .cut:
      return NSSelectorFromString("cut:")
    case .copy:
      return NSSelectorFromString("copy:")
    case .paste:
      return NSSelectorFromString("paste:")
    case .selectAll:
      return NSSelectorFromString("selectAll:")
    }
  }
}

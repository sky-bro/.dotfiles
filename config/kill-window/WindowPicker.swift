import AppKit
import CoreGraphics
import Darwin

enum LockError: Error { case busy, unavailable }

final class PickerLock {
  private let descriptor: Int32

  init(path: String) throws {
    descriptor = Darwin.open(path, O_CREAT | O_RDWR | O_CLOEXEC, 0o600)
    guard descriptor >= 0 else { throw LockError.unavailable }
    guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
      let code = errno
      Darwin.close(descriptor)
      throw code == EWOULDBLOCK ? LockError.busy : LockError.unavailable
    }
  }

  deinit { Darwin.close(descriptor) }
}

struct WindowRecord {
  let id: CGWindowID
  let pid: pid_t
  let owner: String
  let bounds: CGRect
  let layer: Int

  static func visible() -> [WindowRecord] {
    let raw =
      CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
      ) as? [[String: Any]] ?? []
    return raw.compactMap { item in
      guard let id = item[kCGWindowNumber as String] as? UInt32,
        let pid = item[kCGWindowOwnerPID as String] as? Int32,
        let dictionary = item[kCGWindowBounds as String] as? [String: Any],
        let bounds = CGRect(dictionaryRepresentation: dictionary as CFDictionary),
        let layer = item[kCGWindowLayer as String] as? Int,
        (item[kCGWindowAlpha as String] as? Double ?? 1) > 0
      else { return nil }
      // New macOS releases may redact owner names. PID remains authoritative.
      let owner =
        item[kCGWindowOwnerName as String] as? String
        ?? NSRunningApplication(processIdentifier: pid)?.localizedName ?? "Process \(pid)"
      return WindowRecord(id: id, pid: pid, owner: owner, bounds: bounds, layer: layer)
    }
  }

  static func at(_ point: CGPoint, in windows: [WindowRecord]) -> WindowRecord? {
    // Core Graphics returns front-to-back order, including elevated dialogs.
    windows.first {
      $0.pid != getpid() && $0.layer < Int(CGWindowLevelForKey(.screenSaverWindow))
        && $0.bounds.contains(point) && $0.bounds.width > 1
        && $0.bounds.height > 1
    }
  }
}

struct ProcessIdentity: Equatable {
  let pid: pid_t
  let startedSeconds: UInt64
  let startedMicroseconds: UInt64
  let executable: String
  let uid: uid_t

  static func read(_ pid: pid_t) -> ProcessIdentity? {
    guard pid > 1 else { return nil }
    var info = proc_bsdinfo()
    let size = Int32(MemoryLayout<proc_bsdinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
    var path = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
    guard proc_pidpath(pid, &path, UInt32(path.count)) > 0 else { return nil }
    return ProcessIdentity(
      pid: pid, startedSeconds: info.pbi_start_tvsec,
      startedMicroseconds: info.pbi_start_tvusec, executable: String(cString: path),
      uid: info.pbi_uid)
  }

  var isProtected: Bool {
    let name = URL(fileURLWithPath: executable).lastPathComponent
    return pid == getpid() || uid != getuid()
      || [
        "WindowServer", "loginwindow", "launchd", "kernel_task", "Dock", "Finder",
        "SystemUIServer", "ControlCenter", "KillWindow",
      ].contains(name)
  }

  func forceQuit() throws {
    guard !isProtected else { throw PickerError.message("不允许结束系统桌面组件、其他用户或自身进程。") }
    guard Self.read(pid) == self else {
      throw PickerError.message("进程已退出或身份发生变化，请重新选择。")
    }
    guard Darwin.kill(pid, SIGKILL) == 0 else {
      throw PickerError.message("无法结束 PID \(pid)：\(String(cString: strerror(errno)))")
    }
  }
}

enum PickerError: Error {
  case message(String)
  var text: String {
    switch self {
    case .message(let text): return text
    }
  }
}

final class PickerWindow: NSWindow {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}

final class PickerView: NSView {
  var choose: ((CGPoint) -> Void)?
  var cancel: (() -> Void)?
  override var acceptsFirstResponder: Bool { true }
  override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }
  override func mouseDown(with event: NSEvent) {
    // Use the coordinates saved in the click, not a later sample of the moving pointer.
    if let point = event.cgEvent?.location {
      choose?(point)
    } else if let window = event.window, let primary = NSScreen.screens.first {
      let point = window.convertPoint(toScreen: event.locationInWindow)
      choose?(CGPoint(x: point.x, y: primary.frame.maxY - point.y))
    }
  }
  override func rightMouseDown(with event: NSEvent) { cancel?() }
  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 { cancel?() }
  }
  override func draw(_ dirtyRect: NSRect) {
    NSColor.black.withAlphaComponent(0.06).setFill()
    bounds.fill()
    let text = "点击要结束的窗口 · Esc / 右键取消"
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
      .foregroundColor: NSColor.white,
    ]
    let size = text.size(withAttributes: attributes)
    let box = NSRect(
      x: (bounds.width - size.width) / 2 - 20,
      y: bounds.height - 105, width: size.width + 40, height: size.height + 24)
    NSColor.black.withAlphaComponent(0.8).setFill()
    NSBezierPath(roundedRect: box, xRadius: 12, yRadius: 12).fill()
    text.draw(at: NSPoint(x: box.minX + 20, y: box.minY + 12), withAttributes: attributes)
  }
}

final class Picker: NSObject, NSApplicationDelegate {
  private var overlays: [NSWindow] = []
  private let dryRun: Bool
  private var choosing = false

  init(dryRun: Bool) { self.dryRun = dryRun }

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard !WindowRecord.visible().isEmpty else {
      finishWithError("无法读取窗口列表。请从本机终端运行；受限沙盒或非图形会话可能无法访问窗口。")
      return
    }
    NSApp.activate(ignoringOtherApps: true)
    for screen in NSScreen.screens {
      let window = PickerWindow(
        contentRect: screen.frame, styleMask: .borderless,
        backing: .buffered, defer: false)
      window.level = .screenSaver
      window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
      window.isOpaque = false
      window.backgroundColor = .clear
      window.hasShadow = false
      window.isReleasedWhenClosed = false
      let view = PickerView(frame: NSRect(origin: .zero, size: screen.frame.size))
      view.choose = { [weak self] point in self?.select(at: point) }
      view.cancel = { NSApp.terminate(nil) }
      window.contentView = view
      window.makeFirstResponder(view)
      window.orderFrontRegardless()
      overlays.append(window)
    }
    // Give the screen under the pointer keyboard focus, including external displays.
    (overlays.first { $0.frame.contains(NSEvent.mouseLocation) } ?? overlays.first)?
      .makeKeyAndOrderFront(nil)
  }

  private func dismissOverlays() {
    for window in overlays { window.orderOut(nil) }
  }

  private func select(at point: CGPoint) {
    guard !choosing else { return }
    choosing = true
    guard let target = WindowRecord.at(point, in: WindowRecord.visible())
    else {
      dismissOverlays()
      finishWithError("此位置没有可识别的窗口，请重新运行并点击窗口内部。")
      return
    }
    dismissOverlays()
    guard let identity = ProcessIdentity.read(target.pid) else {
      finishWithError("无法读取 \(target.owner)（PID \(target.pid)）的身份，或进程已经退出。未结束任何进程。")
      return
    }
    guard !identity.isProtected else {
      finishWithError("所选的是受保护的桌面组件、其他用户或本工具。未结束任何进程。")
      return
    }
    let alert = NSAlert()
    alert.messageText = dryRun ? "已识别窗口（只查看）" : "强制结束 \(target.owner)？"
    alert.informativeText =
      "应用：\(target.owner)\nPID：\(target.pid)\n程序：\(identity.executable)\n\n"
      + (dryRun
        ? "只查看模式，不会发送结束信号。"
        : "将结束拥有这个窗口的整个进程，包括它的其他窗口。未保存的内容会丢失。")
    alert.addButton(withTitle: dryRun ? "关闭" : "取消")
    if !dryRun { alert.addButton(withTitle: "强制结束") }
    alert.window.level = .screenSaver
    let answer = alert.runModal()
    guard !dryRun, answer == .alertSecondButtonReturn else {
      NSApp.terminate(nil)
      return
    }
    // Recheck the selected window and process identity after the confirmation dialog.
    guard WindowRecord.visible().contains(where: { $0.id == target.id && $0.pid == target.pid })
    else {
      finishWithError("所选窗口已经消失，请重新选择。未结束任何进程。")
      return
    }
    do {
      try identity.forceQuit()
      // SIGKILL is asynchronous. Check for the original identity, not mere PID existence.
      let deadline = Date().addingTimeInterval(2)
      while ProcessIdentity.read(target.pid) == identity && Date() < deadline {
        Thread.sleep(forTimeInterval: 0.05)
      }
      if ProcessIdentity.read(target.pid) == identity {
        finishWithError("已发送强制结束信号，但尚未确认进程退出。")
      } else {
        NSApp.terminate(nil)
      }
    } catch let error as PickerError { finishWithError(error.text) } catch {
      finishWithError(error.localizedDescription)
    }
  }

  private func finishWithError(_ message: String) {
    dismissOverlays()
    let alert = NSAlert()
    alert.messageText = "Kill Window"
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "关闭")
    alert.window.level = .screenSaver
    alert.runModal()
    NSApp.terminate(nil)
  }
}

func selfTest() throws {
  func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw PickerError.message("FAIL: \(message)") }
  }
  let lockPath = NSTemporaryDirectory() + "kill-window-lock-test-" + UUID().uuidString
  defer { try? FileManager.default.removeItem(atPath: lockPath) }
  var firstLock: PickerLock? = try PickerLock(path: lockPath)
  try expect(firstLock != nil, "first picker must acquire lock")
  do {
    _ = try PickerLock(path: lockPath)
    throw PickerError.message("duplicate picker acquired lock")
  } catch LockError.busy {}
  firstLock = nil
  let replacementLock = try PickerLock(path: lockPath)
  withExtendedLifetime(replacementLock) {}
  let dialog = WindowRecord(
    id: 1, pid: 123, owner: "App Store",
    bounds: CGRect(x: 1498, y: 417, width: 497, height: 230), layer: 8)
  let background = WindowRecord(
    id: 2, pid: 124, owner: "Browser",
    bounds: CGRect(x: 0, y: 30, width: 2560, height: 1410), layer: 0)
  let overlay = WindowRecord(
    id: 3, pid: getpid(), owner: "Kill Window",
    bounds: CGRect(x: 0, y: 0, width: 2560, height: 1440), layer: 1000)
  let cursor = WindowRecord(
    id: 5, pid: 126, owner: "Window Server",
    bounds: CGRect(x: 1590, y: 490, width: 70, height: 100), layer: Int(Int32.max) - 17)
  try expect(
    WindowRecord.at(CGPoint(x: 1600, y: 500), in: [cursor, overlay, dialog, background])?.pid
      == 123,
    "layer-8 dialog must beat background and ignore cursor/picker overlays")
  try expect(
    WindowRecord.at(CGPoint(x: 100, y: 500), in: [dialog, background])?.pid == 124,
    "point outside dialog must select background")
  try expect(
    WindowRecord.at(CGPoint(x: -1000, y: -1000), in: [dialog, background]) == nil,
    "empty desktop must not select an unrelated process")
  let external = WindowRecord(
    id: 4, pid: 125, owner: "External",
    bounds: CGRect(x: -1600, y: -900, width: 1600, height: 900), layer: 0)
  try expect(
    WindowRecord.at(CGPoint(x: -800, y: -400), in: [external, background])?.pid == 125,
    "negative display coordinates must be preserved")
  guard let own = ProcessIdentity.read(getpid()) else {
    throw PickerError.message("Cannot inspect the current process in this environment.")
  }
  try expect(own.isProtected, "picker must refuse to terminate itself")
  // Integration smoke: only signal a disposable child created by this test.
  let child = Process()
  child.executableURL = URL(fileURLWithPath: "/bin/sleep")
  child.arguments = ["30"]
  try child.run()
  defer {
    if child.isRunning { child.terminate() }
    child.waitUntilExit()
  }
  guard let identity = ProcessIdentity.read(child.processIdentifier) else {
    throw PickerError.message("Cannot inspect disposable child process.")
  }
  let stale = ProcessIdentity(
    pid: identity.pid, startedSeconds: identity.startedSeconds + 1,
    startedMicroseconds: identity.startedMicroseconds,
    executable: identity.executable, uid: identity.uid)
  do {
    try stale.forceQuit()
    throw PickerError.message("stale process identity was accepted")
  } catch PickerError.message(let message) {
    try expect(message.contains("身份发生变化"), "reused/stale PID must be refused")
  }
  try expect(child.isRunning, "stale identity check must leave child alive")
  try identity.forceQuit()
  child.waitUntilExit()
  try expect(
    child.terminationReason == .uncaughtSignal && child.terminationStatus == SIGKILL,
    "force quit must terminate disposable child with SIGKILL")
  print(
    "PASS: automatic lock release, duplicate picker rejection, stacked dialogs, overlay exclusion, empty space, multiple displays, protected self, stale PID, child termination"
  )
}

let option = CommandLine.arguments.dropFirst().first ?? "--pick"
switch option {
case "--self-test":
  do { try selfTest() } catch let error as PickerError {
    fputs(error.text + "\n", stderr)
    exit(1)
  } catch {
    fputs(error.localizedDescription + "\n", stderr)
    exit(1)
  }
case "--list":
  let windows = WindowRecord.visible()
  guard !windows.isEmpty else {
    fputs(
      "No window metadata available; run from the local graphical session outside a restricted sandbox.\n",
      stderr)
    exit(1)
  }
  for window in windows {
    print("PID=\(window.pid) APP=\(window.owner) LAYER=\(window.layer) BOUNDS=\(window.bounds)")
  }
case "--pick", "--dry-run":
  let lock: PickerLock
  do {
    lock = try PickerLock(
      path: Bundle.main.bundleURL.deletingLastPathComponent()
        .appendingPathComponent("picker.lock").path)
  } catch LockError.busy {
    NSRunningApplication.runningApplications(withBundleIdentifier: "com.sky.dotfiles.kill-window")
      .first { $0.processIdentifier != getpid() }?.activate(options: [])
    exit(0)
  } catch {
    fputs("Cannot acquire picker lock.\n", stderr)
    exit(1)
  }
  let app = NSApplication.shared
  app.setActivationPolicy(.accessory)
  let picker = Picker(dryRun: option == "--dry-run")
  app.delegate = picker
  withExtendedLifetime((picker, lock)) { app.run() }
default:
  fputs("Unknown option\n", stderr)
  exit(2)
}

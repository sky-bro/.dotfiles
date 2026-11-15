// Product helper: no Apple Events, clipboard, shell, secret argv or plaintext files.
// Window IDs/PIDs are metadata. Credentials only arrive on stdin for `type`.
ObjC.import("AppKit");
ObjC.import("ApplicationServices");
// Explicitly typed allocation keeps the UTF-16 pointer compatible with Quartz.
ObjC.bindFunction("calloc", ["unsigned short *", ["unsigned long", "unsigned long"]]);
ObjC.bindFunction("free", ["void", ["unsigned short *"]]);
function windows() {
  var result = $.CGWindowListCopyWindowInfo($.kCGWindowListOptionOnScreenOnly | $.kCGWindowListExcludeDesktopElements, 0);
  if (!result) throw new Error("target");
  // JXA owns returned Core Foundation references; manual CFRelease double-frees.
  return ObjC.deepUnwrap(ObjC.castRefToObject(result));
}
function targetFor(windowId, list) {
  list = list || windows();
  for (var i = 0; i < list.length; i++) {
    if (String(list[i].kCGWindowNumber) === String(windowId) && Number(list[i].kCGWindowLayer) === 0) {
      var pid = Number(list[i].kCGWindowOwnerPID);
      var app = $.NSRunningApplication.runningApplicationWithProcessIdentifier(pid);
      if (!app || !app.launchDate || /vicinae|pinentry/i.test(ObjC.unwrap(app.bundleIdentifier) || ObjC.unwrap(app.localizedName) || "")) break;
      return { windowId: String(windowId), pid: pid, launched: Number(app.launchDate.timeIntervalSince1970) };
    }
  }
  throw new Error("target");
}
function checkTarget(target) {
  var list = windows();
  var current = targetFor(target.windowId, list);
  var front = $.NSWorkspace.sharedWorkspace.frontmostApplication;
  if (current.pid !== target.pid || current.launched !== target.launched || !front || Number(front.processIdentifier) !== target.pid) throw new Error("focus");
  for (var i = 0; i < list.length; i++) {
    if (Number(list[i].kCGWindowOwnerPID) === target.pid && Number(list[i].kCGWindowLayer) === 0) {
      if (String(list[i].kCGWindowNumber) !== target.windowId) throw new Error("focus");
      return;
    }
  }
  throw new Error("focus");
}
function makeEvent(source, text, keyCode, down) {
  var event = $.CGEventCreateKeyboardEvent(source, keyCode, down);
  if (!event) throw new Error("event");
  $.CGEventSetFlags(event, 0);
  if (text) {
    var units = $.calloc(text.length, 2);
    if (!units) throw new Error("event");
    try {
      for (var i = 0; i < text.length; i++) units[i] = text.charCodeAt(i);
      $.CGEventKeyboardSetUnicodeString(event, text.length, units);
    } finally {
      for (var i = 0; i < text.length; i++) units[i] = 0;
      $.free(units);
    }
  }
  return event;
}
function postPair(source, target, text, code) {
  checkTarget(target);
  var down = makeEvent(source, text, code, true);
  var up = makeEvent(source, text, code, false);
  // PID-directed delivery also prevents another app receiving an event if
  // focus changes between checking and posting. Never post globally.
  $.CGEventPostToPid(target.pid, down);
  $.CGEventPostToPid(target.pid, up);
  $.NSThread.sleepForTimeInterval(0.012);
}
function selfTest() {
  // Public fixture only: verifies real Quartz UTF-16 encoding without posting.
  var text = "Fixture-测试-🔐";
  var event = makeEvent(null, text, 0, true);
  var units = $.calloc(text.length, 2);
  try {
    var length = Ref();
    $.CGEventKeyboardGetUnicodeString(event, text.length, length, units);
    var decoded = "";
    for (var i = 0; i < text.length; i++) decoded += String.fromCharCode(units[i]);
    if (decoded !== text) throw new Error("event");
  } finally { $.free(units); }
  return { unicodeRoundTrip: true, trusted: !!$.AXIsProcessTrusted() };
}
function run(argv) {
  var sent = false;
  try {
    if (argv[0] === "self-test") return JSON.stringify(selfTest());
    var bytes = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
    if (Number(bytes.length) > 65536) throw new Error("input");
    var request = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding(bytes, $.NSUTF8StringEncoding)));
    if (!$.AXIsProcessTrusted()) throw new Error("permission");
    if (request.operation === "permissions") return JSON.stringify({ ready: true });
    if (request.operation === "prepare") return JSON.stringify({ target: targetFor(request.windowId) });
    if (request.operation !== "type" || !Array.isArray(request.steps) || !request.steps.length || request.steps.length > 3) throw new Error("input");
    var target = request.target;
    if (!target || !/^\d+$/.test(target.windowId) || !Number.isInteger(target.pid) || target.pid <= 0 || !Number.isFinite(target.launched)) throw new Error("input");
    for (var i = 0; i < request.steps.length; i++) {
      var step = request.steps[i];
      if (typeof step.text === "string") {
        if (!step.text.length || step.text.length > 1024 || /[\x00-\x1f\x7f-\x9f\u2028\u2029]/.test(step.text)) throw new Error("input");
      } else if (step.key !== "tab") throw new Error("input");
    }
    // Wait for the launch shortcut modifiers to be released, with a bound.
    var modifierMask = 131072 | 262144 | 524288 | 1048576;
    var tries = 0;
    while (Number($.CGEventSourceFlagsState($.kCGEventSourceStateCombinedSessionState)) & modifierMask) {
      if (++tries > 40) throw new Error("modifiers");
      $.NSThread.sleepForTimeInterval(0.025);
    }
    checkTarget(target);
    var source = $.CGEventSourceCreate($.kCGEventSourceStatePrivate);
    if (!source) throw new Error("event");
    for (var i = 0; i < request.steps.length; i++) {
      var step = request.steps[i];
      if (step.key === "tab") {
        sent = true; postPair(source, target, "", 48);
        $.NSThread.sleepForTimeInterval(0.15);
      } else {
        for (var j = 0; j < step.text.length; j++) {
          var text = step.text.charAt(j); var code = step.text.charCodeAt(j);
          if (code >= 0xd800 && code <= 0xdbff && j + 1 < step.text.length) text += step.text.charAt(++j);
          sent = true; postPair(source, target, text, 0);
        }
      }
    }
    return JSON.stringify({ sent: true });
  } catch (error) {
    var code = String(error.message);
    if (!["permission", "focus", "target", "input", "modifiers", "event"].includes(code)) code = "event";
    return JSON.stringify({ error: code, partial: sent });
  }
}

// JXA helper: secrets arrive only on stdin; stdout contains only changeCount.
ObjC.import("AppKit");
ObjC.import("Foundation");

function run(argv) {
  var board = $.NSPasteboard.generalPasteboard;
  if (!board || !/^[0-9]+$/.test(String(board.changeCount))) {
    throw new Error("The macOS pasteboard is unavailable.");
  }
  if (argv[0] === "clear") {
    if (!/^[0-9]+$/.test(argv[1] || "") || !/^[1-9][0-9]{0,4}$/.test(argv[2] || "")) {
      throw new Error("Invalid clipboard timer.");
    }
    $.NSThread.sleepForTimeInterval(Number(argv[2]));
    if (Number(board.changeCount) === Number(argv[1])) board.clearContents;
    return;
  }
  if (argv[0] !== "copy") throw new Error("Expected copy or clear.");

  var bytes = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
  var text = $.NSString.alloc.initWithDataEncoding(bytes, $.NSUTF8StringEncoding);
  if (!text || !Number(text.length)) throw new Error("No password supplied.");
  // Direct writes keep data available after this short-lived process exits.
  // Declare all marker types before making the plaintext available.
  board.declareTypesOwner([
    "public.utf8-plain-text",
    "org.nspasteboard.ConcealedType",
    "org.nspasteboard.TransientType"
  ], null);
  if (!board.setDataForType($.NSData.data, "org.nspasteboard.ConcealedType") ||
      !board.setDataForType($.NSData.data, "org.nspasteboard.TransientType") ||
      !board.setStringForType(text, "public.utf8-plain-text")) {
    board.clearContents;
    throw new Error("Could not write confidential clipboard data.");
  }
  return String(board.changeCount);
}

// Local-only QR decoding. Paths and decoded seeds travel through pipes, never argv.
ObjC.import("AppKit");
ObjC.import("Foundation");
ObjC.import("CoreImage");
ObjC.import("Vision");
function run() {
  try {
    var bytes = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
    var request = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding(bytes, $.NSUTF8StringEncoding)));
    var data;
    if (request.source === "file") {
      var attributes = $.NSFileManager.defaultManager.attributesOfItemAtPathError($(request.path), null);
      if (!attributes || Number(attributes.objectForKey($.NSFileSize)) > 20 * 1024 * 1024 || ObjC.unwrap(attributes.objectForKey($.NSFileType)) !== ObjC.unwrap($.NSFileTypeRegular)) throw new Error();
      data = $.NSData.dataWithContentsOfFile($(request.path));
    } else if (request.source === "clipboard") {
      var board = $.NSPasteboard.generalPasteboard;
      data = board.dataForType("public.png");
      if (!data || !Number(data.length)) data = board.dataForType("public.tiff");
    } else throw new Error();
    if (!data || !Number(data.length) || Number(data.length) > 20 * 1024 * 1024) throw new Error();
    var image = $.CIImage.imageWithData(data);
    if (!image) throw new Error();
    var extent = image.extent;
    if (extent.size.width * extent.size.height > 40000000) throw new Error();
    var detection = $.VNDetectBarcodesRequest.alloc.init;
    detection.symbologies = $([$.VNBarcodeSymbologyQR]);
    var handler = $.VNImageRequestHandler.alloc.initWithCIImageOptions(image, $({}));
    if (!handler.performRequestsError($([detection]), null)) throw new Error();
    var results = detection.results; var values = [];
    if (Number(results.count) > 64) throw new Error();
    for (var i = 0; i < Number(results.count); i++) {
      var payload = results.objectAtIndex(i).payloadStringValue;
      if (payload) values.push(ObjC.unwrap(payload));
    }
    return JSON.stringify(values);
  } catch (_) { throw new Error("Could not decode a local QR image (PNG, JPEG or TIFF, up to 20 MB / 40 megapixels)."); }
}

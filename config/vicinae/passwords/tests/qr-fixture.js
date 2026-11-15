ObjC.import('AppKit'); ObjC.import('CoreImage');
// Public RFC 6238 fixture only. Never feed real credentials to this generator.
function run(argv) {
 var filter = $.CIFilter.filterWithName('CIQRCodeGenerator');
 var text = $('otpauth://totp/Fixture:alice?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Fixture');
 filter.setValueForKey(text.dataUsingEncoding($.NSUTF8StringEncoding), 'inputMessage');
 var image = filter.outputImage.imageByApplyingTransform($.CGAffineTransformMakeScale(8,8));
 var rep = $.NSCIImageRep.imageRepWithCIImage(image);
 var ns = $.NSImage.alloc.initWithSize(rep.size); ns.addRepresentation(rep);
 var bitmap = $.NSBitmapImageRep.imageRepWithData(ns.TIFFRepresentation);
 var png = bitmap.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $({}));
 if (!png.writeToFileAtomically(argv[0],true)) throw Error('write');
 if (argv[1] === 'clipboard') {
   var board = $.NSPasteboard.generalPasteboard; board.clearContents;
   if (!board.setDataForType(png,'public.png')) throw Error('clipboard');
 }
 return 'Synthetic QR created';
}

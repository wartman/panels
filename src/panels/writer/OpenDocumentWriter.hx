package panels.writer;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;

class OpenDocumentWriter extends Writer {
  public function new() {}

  public function write(path:String, content:String):Task<Nothing> {
    // Note: saving as a `flat` ODT, which is a single XML document version
    // of the spec for simplicity. We should look into the real, ZIP based
    // version for later.
    var fullPath = path.withExtension('fodt');
    ensureDir(fullPath);
    fullPath.saveContent(content);
    return Nothing;
  }
}

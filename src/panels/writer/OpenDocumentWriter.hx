package panels.writer;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;

class OpenDocumentWriter {
  public function new() {}

  public function write(path:String, content:Xml) {
    // Note: saving as a `flat` ODT, which is a single XML document version
    // of the spec for simplicity. We should look into the real, ZIP based
    // version for later.
    path.withExtension('fodt').saveContent(content.toString());
  }
}

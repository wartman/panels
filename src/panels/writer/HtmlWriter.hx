package panels.writer;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;

class HtmlWriter extends Writer {
  public function new() {}

  public function write(path:String, content:String):Task<Nothing> {
    var fullPath = path.withExtension('html');
    ensureDir(fullPath);
    fullPath.saveContent(content);
    return Nothing;
  }
}

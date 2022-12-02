package panels.writer;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;
using tink.CoreApi;

class HtmlWriter extends Writer {
  public function new() {}

  public function write(path:String, content:String):Promise<Noise> {
    var fullPath = path.withExtension('html');
    ensureDir(fullPath);
    fullPath.saveContent(content);
    return Noise;
  }
}

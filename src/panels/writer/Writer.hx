package panels.writer;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;

abstract class Writer {
  abstract public function write(path:String, content:String):Task<Nothing>;

  function ensureDir(path:String) {
    var dir = path.directory();
    if (!dir.isDirectory()) {
      if (dir.exists()) {
        throw 'Cannot write to the directory ${dir} as it is an existing file';
        return;
      }

      try {
        dir.createDirectory();
      } catch (e) {
        throw 'Unable to create the directory ${dir}: ${e.message}';
        return;
      }
    }
  }
}

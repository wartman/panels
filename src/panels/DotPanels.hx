package panels;

import haxe.ds.Option;
import haxe.Json;
import panels.PanelsConfig;

using Reflect;
using haxe.io.Path;
using sys.FileSystem;
using sys.io.File;

class DotPanels {
  public static function find(path:String):Option<PanelsConfig> {
    var path = switch locateDotPanelsFile(path) {
      case Some(path): path;
      case None: return None;
    }

    var source:Source = {
      file: path,
      content: path.getContent()
    };
    var dotPanels = new DotPanels(source);

    return Some(dotPanels.parse());
  }

  static function locateDotPanelsFile(root:String):Option<String> {
    var path = Path.join([root, '.panels']);

    if (path.exists()) return Some(path);

    var dir = root.directory();
    if (dir.exists()) return locateDotPanelsFile(dir);

    return None;
  }

  final source:Source;

  public function new(source:Source) {
    this.source = source;
  }

  function parse():PanelsConfig {
    var data:Dynamic = Json.parse(source.content);
    var compiler = getOr(data, 'compiler', {});
    var validator = getOr(data, 'validator', {});

    // @todo: We need to do some validation at some point, but for now...
    return ({
      compiler: {
        startPage: getOr(compiler, 'startPage', 1),
        includeSections: getOr(compiler, 'includeSections', false),
        includeFrontmatter: getOr(compiler, 'includeFrontmatter', true)
      },
      validator: {
        requireTitle: getOr(validator, 'requireTitle', false),
        requireAuthor: getOr(validator, 'requireAuthor', false),
        maxPanelsPerPage: getOr(validator, 'maxPanelsPerPage', null),
        maxWordsPerDialog: getOr(validator, 'maxWordsPerDialog', null),
        checkPanelOrder: getOr(validator, 'checkPanelOrder', true),
      }
    } : PanelsConfig);
  }

  function getOr<T>(data:Dynamic, field:String, def:T):T {
    if (!data.hasField(field)) return def;
    return data.field(field);
  }
}

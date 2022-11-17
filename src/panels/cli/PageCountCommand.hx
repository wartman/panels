package panels.cli;

import cmdr.*;
import cmdr.style.DefaultStyles.*;

using sys.FileSystem;
using sys.io.File;
using haxe.io.Path;
using cmdr.style.StyleTools;

class PageCountCommand extends Command {
  @:argument var source:String;

  public function new() {}

  public function getDescription():Null<String> {
    return 'Get a count of the current number of pages';
  }

  function process(input:Input, output:Output):ExitCode {
    var file = Path.join([Sys.getCwd(), source]);

    if (file.extension() == '') file = file.withExtension('pan');
    if (!file.exists()) {
      output.writeLn('No file exists named $file');
      return Failure;
    }

    var reporter = new VisualReporter();
    var source:Source = {
      file: file,
      content: file.getContent()
    };

    try {
      var parser = new Parser(source);
      var node = parser.parse();
      var pages:Int = switch node.node {
        case Document(frontmatter, nodes):
          nodes.filter(n -> switch n.node {
            case Page(_): true;
            default: false;
          }).length;
        default: 0;
      }

      output.writeLn('There are ${(' ' + pages + ' ').useStyle(bold, bgWhite)} pages in the document ${file}');
    } catch (e:ParserException) {
      reporter.report(e.toReporterMessage(), source);
      return Failure;
    }

    return Success;
  }
}

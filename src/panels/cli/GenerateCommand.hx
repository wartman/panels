package panels.cli;

import cmdr.*;
import panels.writer.*;
import panels.generator.*;
import cmdr.style.DefaultStyles.*;

using sys.FileSystem;
using sys.io.File;
using haxe.io.Path;
using cmdr.style.StyleTools;

class GenerateCommand extends Command {
  @:argument var source:String;

  @:option('f', description = 'The kind of file to generate. Can currently be odt or html.') var format:String = 'odt';
  @:option('d', description = 'Set the output destination (optional)') var destination:String = null;
  @:option(description = 'Require that the author includes a title.') var requireTitle:Bool = false;
  @:option(description = 'Require that the author includes an author.') var requireAuthor:Bool = false;
  @:option(description = 'Set the max number of panels allowed per page.') var maxPanelsPerPage:Int = null;

  public function new() {}

  public function getDescription():Null<String> {
    return 'Generate a file from the given input';
  }

  function process(input:Input, output:Output):ExitCode {
    var file = Path.join([Sys.getCwd(), source]);
    var dest = destination != null ? destination : Path.join([Sys.getCwd(), source.withoutExtension()]);

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
      var content:String = switch format {
        case 'html': new HtmlGenerator(node).generate();
        case 'odt': new OpenDocumentGenerator(node).generate().toString();
        default: throw 'Invalid format: $format';
      }
      var writer:Writer = switch format {
        case 'html': new HtmlWriter();
        case 'odt': new OpenDocumentWriter();
        default: throw 'Invalid format: $format';
      }
      writer.write(dest, content);
      output.writeLn('Compiled ${file} to ${dest} ' + 'successfully'.useStyle(bold));
    } catch (e:ParserException) {
      reporter.report(e.toReporterMessage(), source);
      return Failure;
    }

    return Success;
  }
}

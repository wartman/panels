package panels.cli;

import panels.writer.*;
import panels.generator.*;

using sys.FileSystem;
using sys.io.File;
using haxe.io.Path;

// @todo: This is kinda a mess
class App {
  final args:AppArgs;

  public function new(args) {
    this.args = args;
  }

  public function process() {
    // @todo: add support for `--help`

    var file = Path.join([Sys.getCwd(), args.source]);
    var format = args.format != null ? args.format : 'odt';
    var output = args.output != null ? args.output : Path.join([Sys.getCwd(), args.source.withoutExtension()]);

    if (file.extension() == '') file = file.withExtension('pan');
    if (!file.exists()) {
      throw 'No file exists named $file';
    }

    var reporter = new VisualReporter();
    var source:Source = {
      file: file,
      content: file.getContent()
    };

    try {
      var parser = new Parser(source);
      var node = parser.parse();
      var validator = new Validator(node, args);
      var warnings = validator.validate();
      var content:String = switch format {
        case 'html': new HtmlGenerator(node).generate();
        case 'odt': new OpenDocumentGenerator(node).generate().toString();
        default: throw 'Invalid format: $format';
      }
      for (warning in warnings) reporter.report(warning, source);
      var writer:Writer = switch format {
        case 'html': new HtmlWriter();
        case 'odt': new OpenDocumentWriter();
        default: throw 'Invalid format: $format';
      }
      writer.write(output, content);
      Sys.println('Compiled ${args.source} to $output successfully');
    } catch (e:ParserException) {
      reporter.report(e.toReporterMessage(), source);
    }
  }
}

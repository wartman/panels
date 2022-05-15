import panels.writer.OpenDocumentWriter;
import haxe.xml.Printer;
import panels.generator.OpenDocumentGenerator;
import panels.*;

using sys.io.File;
using haxe.io.Path;

function main() {
  var file = Path.join([Sys.programPath().directory(), 'test.pan']);
  var source:Source = {
    file: file,
    content: file.getContent()
  };
  var reporter = new VisualReporter();
  try {
    var parser = new Parser(source);
    var node = parser.parse();
    var validator = new Validator(node, {
      maxPanelsPerPage: 6,
      requireTitle: true,
      requireAuthor: true
    });
    var warnings = validator.validate();
    var generator = new OpenDocumentGenerator(node);
    var content = generator.generate();

    for (warning in warnings) reporter.report(warning, source);

    var writer = new OpenDocumentWriter();
    writer.write(Path.join([Sys.programPath().directory(), 'test.fodt']), content);
  } catch (e:ParserException) {
    reporter.report(e.toReporterMessage(), source);
  }
}

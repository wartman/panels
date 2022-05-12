import panels.ParserException;
import panels.VisualReporter;
import panels.Source;
import panels.HtmlGenerator;
import panels.Parser;

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
    var generator = new HtmlGenerator(node);
    var content = generator.generate();
    Path.join([Sys.programPath().directory(), 'test.html']).saveContent(content);
  } catch (e:ParserException) {
    reporter.report(e, source);
  }
}

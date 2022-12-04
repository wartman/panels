package panels.cli;

import cmdr.*;
import panels.writer.*;
import panels.generator.*;

using sys.FileSystem;
using sys.io.File;
using haxe.io.Path;
using tink.CoreApi;
using cmdr.StyleTools;

class App implements Command {
  /**
    What file format to generate. Currently can be "odt" or "html".
  **/
  @:alias('f')
  @:flag
  public var format:String = 'odt';

  /**
    Where the generated file should be saved. If left blank,
    Panels will save it next to the input file. 
  **/
  @:alias('d')
  @:flag
  public var destination:String = null;

  /**
    If true, Panels will fail to compile if the "Title: ..."
    property is not present in your script's header.
  **/
  @:alias('t')
  @:flag
  public var requireTitle:Bool = false;

  /**
    If true, Panels will fail to compile if the "Author: ..."
    property is not present in your script's header.
  **/
  @:alias('a')
  @:flag
  public var requireAuthor:Bool = false;

  /**
    If set, Panels will warn you if any of your pages have
    more than the allowed number of panels.
  **/
  @:flag
  public var maxPanelsPerPage:Int = null;

  public function new() {}

  /**
    Compile your panels script. By default, this will be 
    saved next to your panels file with the same name.
  **/
  @:command
  public function generate(src:String):Result {
    var file = Path.join([Sys.getCwd(), src]);
    var dest = destination != null ? destination : Path.join([Sys.getCwd(), src.withoutExtension()]);

    if (format == null && dest.extension() != null) {
      format = dest.extension();
      dest = dest.withoutExtension();
    }

    return getSource(file).next(source -> {
      var generator = switch format {
        case 'odt': new OpenDocumentGenerator();
        case 'html': new HtmlGenerator();
        default: return new Error(NotFound, 'Invalid format: $format');
      }
      var compiler = new Compiler(source, new VisualReporter(), generator, {
        requireAuthor: requireAuthor,
        maxPanelsPerPage: maxPanelsPerPage
      });
      return compiler.compile();
    }).next(content -> {
      var writer:Writer = switch format {
        case 'html': new HtmlWriter();
        case 'odt': new OpenDocumentWriter();
        default: return new Error(InternalError, 'Invalid format: $format');
      }
      return writer.write(dest, content);
    }).next(_ -> {
      output.writeLn('')
        .write('    ')
        .write(' Success '.bold().backgroundColor(Yellow))
        .write(' Compiled ')
        .write(file.bold())
        .write(' to ')
        .writeLn(dest.withExtension(format).bold());
      return Noise;
    });
  }

  /**
    Get information about your script (such as the current number of pages)
    without creating any output.
  **/
  @:command
  public function info(src:String):Result {
    var file = Path.join([Sys.getCwd(), src]);

    return getSource(file).next(source -> {
      var compiler = new Compiler(source, new VisualReporter(), new NullGenerator(), {
        requireAuthor: requireAuthor,
        maxPanelsPerPage: maxPanelsPerPage
      });
      return compiler.getMetadata();
    }).next(info -> {
      function writeInfo(label:String, info:Null<String>) {
        if (info == null) {
          info = ' (not provided) '.bold().backgroundColor(Red);
        }
        output.write('    ').write(label).write(': ').write(info).writeLn('');
      }

      output.writeLn('').write('    ').writeLn('Script Info'.bold()).writeLn('');

      writeInfo('Title', info.title);
      writeInfo('Author', info.author);
      writeInfo('Pages', info.pages + '');
      writeInfo('Sections', info.sections.length + '');
      for (section in info.sections) {
        writeInfo('  ' + section.title, section.pages + ' pages');
      }

      return Noise;
    });
  }

  /**
    Tools to compile a Panels script.
  **/
  @:defaultCommand
  public function documentation():Result {
    output.writeLn(getDocs());
    return 0;
  }

  function getSource(file:String):Promise<Source> {
    if (file.extension() == '') file = file.withExtension('pan');
    if (!file.exists()) return new Error(NotFound, 'No file found with that name.');

    var source:Source = {
      file: file,
      content: file.getContent()
    };

    return source;
  }
}

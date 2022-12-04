package panels.cli;

import cmdr.*;
import panels.writer.*;
import panels.generator.*;

using sys.FileSystem;
using sys.io.File;
using haxe.io.Path;
using tink.CoreApi;
using cmdr.StyleTools;

/**
  Tools for compiling and investigating Panels scripts.
**/
class App implements Command {
  /**
    What file format to compile. Currently can be "odt" or "html".
  **/
  @:alias('f')
  @:flag
  public var format:String = 'odt';

  /**
    Where the compiled file should be saved. If left blank,
    Panels will save it next to the input file. 
  **/
  @:alias('d')
  @:flag
  public var destination:String = null;

  /**
    If true, Panels will output section titles in the compiled
    document.
  **/
  @:alias('s')
  public var includeSections:Bool = false;

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
  @:alias('x')
  @:flag
  public var maxPanelsPerPage:Int = null;

  /**
    Makes sure that panel numbers are in order from lowest
    to highest.
  **/
  @:alias('o')
  @:flag
  public var checkPanelOrder:Bool = false;

  /**
    Ignores .panels configuration, if present.
  **/
  @:alias('i')
  @:flag
  public var ignoreDotPanels:Bool = false;

  public function new() {}

  /**
    Compile your panels script. If a .panels file is present in
    the any directory that's a parent of the you're running this cli from, 
    Panels will attempt to load that configuration. Note that you can override
    .panels config with cli flags, or by using --ignoreDotPanels -i.

    (IMPORANT NOTE: .panels won't be overrided yet actually :v)
  **/
  @:command
  public function compile(src:String):Result {
    var file = Path.join([Sys.getCwd(), src]);
    var dest = destination != null ? destination : Path.join([Sys.getCwd(), src.withoutExtension()]);

    if (format == null && dest.extension() != null) {
      format = dest.extension();
      dest = dest.withoutExtension();
    }

    return getSource(file).next(source -> {
      var generator = switch format {
        case 'odt': new OpenDocumentGenerator();
        case 'html': new HtmlGenerator({includeSections: includeSections});
        default: return new Error(NotFound, 'Invalid format: $format');
      }
      var compiler = createCompiler(source, generator);
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
      var compiler = createCompiler(source, new NullGenerator());
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

  function getDefaulConfig():PanelsConfig {
    return {
      compiler: {},
      validator: {
        requireAuthor: requireAuthor,
        maxPanelsPerPage: maxPanelsPerPage,
        checkPanelOrder: checkPanelOrder
      }
    };
  }

  function createCompiler(source:Source, generator) {
    var config:PanelsConfig = if (ignoreDotPanels) {
      output.writeLn('', '    Ignoring .panels config -- using defaults and CLI flags'.color(Yellow));
      getDefaulConfig();
    } else switch DotPanels.find(source.file) {
      case Some(config):
        output.writeLn('', '    Using .panels config'.color(Yellow));
        config;
      case None:
        output.writeLn('', '    No .panels config found -- using defaults and CLI flags'.color(Red));
        getDefaulConfig();
    }

    // @todo: We need to be able to override the .panels config
    return new Compiler(source, new VisualReporter(), generator, config);
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

package panels.cli;

import tink.Cli;
import doc.FileSystem;
import director.*;
// import kit.io.FileSystem;
import panels.generator.*;

// using director.StyleTools;
using haxe.io.Path;

/**
	Tools for compiling and investigating Panels scripts.
**/
class App {
	/**
		What file format to compile. Currently can be "odt" or "html".
	**/
	@:flag('format')
	public var format:String = 'odt';

	/**
		Where the compiled file should be saved. If left blank,
		Panels will save it next to the input file. 
	**/
	@:flag('destination')
	public var destination:String = null;

	/**
		If true, Panels will output section titles in the compiled
		document.
	**/
	@:alias('s')
	@:flag('include-sections')
	public var includeSections:Bool = false;

	/**
		If true, Panels will output panel counts in the compiled
		document next to the page number (e.g. "Page 3 - 4 Panels").
	**/
	@:alias('p')
	@:flag('include-panel-count')
	public var includePanelCount:Bool = false;

	/**
		If true, Panels will fail to compile if the "Title: ..."
		property is not present in your script's header.
	**/
	@:alias('t')
	@:flag('require-title')
	public var requireTitle:Bool = false;

	/**
		If true, Panels will fail to compile if the "Author: ..."
		property is not present in your script's header.
	**/
	@:alias('a')
	@:flag('require-author')
	public var requireAuthor:Bool = false;

	/**
		If set, Panels will warn you if any of your pages have
		more than the allowed number of panels.
	**/
	@:alias('x')
	@:flag('max-panels-per-page')
	public var maxPanelsPerPage:Int = null;

	/**
		Makes sure that panel numbers are in order from lowest to highest.
	**/
	@:alias('o')
	@:flag('check-panel-order')
	public var checkPanelOrder:Bool = false;

	/**
		Ignores .panels configuration, if present.
	**/
	@:alias('i')
	@:flag('ignore-dot-panels')
	public var ignoreDotPanels:Bool = false;

	final fs:FileSystem;

	public function new(?fs:FileSystem) {
		this.fs = fs ?? FileSystem.ofCwd();
	}

	/**
		Compile your panels script. If a .panels file is present in
		any directory that's a parent of the one you're running this app in, 
		Panels will attempt to load that configuration. Note that you can override
		.panels config with cli flags, or by using --ignoreDotPanels -i.

		(IMPORTANT NOTE: .panels won't actually be overridden yet)
	**/
	@:command
	public function compile(src:String):Promise<Int> {
		var dest = destination != null ? destination : src.withoutExtension();

		if (format == null && dest.extension() != null) {
			format = dest.extension();
			dest = dest.withoutExtension();
		}

		return (getSource(src) && (getConfig(src)))
			.next(pair -> createCompiler(pair.b, pair.a).compile() && pair.b)
			.next(pair -> {
				pair.extract(try {a: node, b: config});

				var generator = switch format {
					case 'odt' | 'fodt': new OpenDocumentGenerator(config.compiler);
					case 'html': new HtmlGenerator(config.compiler);
					default: return new Error(NotAcceptable, 'Invalid format: $format');
				}

				generator.save(fs, dest, node);
			})
			.next(_ -> {
				Sys.println('');
				Sys.print('    ');
				Sys.print(' Success ');
				Sys.print(' Compiled ');
				Sys.print(src);
				Sys.print(' to ');
				Sys.println(dest.withExtension(format));
				// console.writeLine('')
				// 	.write('    ')
				// 	.write(' Success '.bold().backgroundColor(Yellow))
				// 	.write(' Compiled ')
				// 	.write(src.bold())
				// 	.write(' to ')
				// 	.writeLine(dest.withExtension(format).bold());
				return 0;
			});
	}

	/**
		Get information about your script (such as the current number of pages)
		without creating any output.
	**/
	@:command
	public function info(src:String):Promise<Int> {
		return (getSource(src) && getConfig(src))
			.next(pair -> createCompiler(pair.b, pair.a).compile().next(node -> Metadata.parse(node)))
			.next(info -> {
				function writeInfo(label:String, info:Null<String>) {
					if (info == null) {
						info = ' (not provided) ';
						// info = ' (not provided) '.bold().backgroundColor(Red);
					}
					Sys.println('    ${label}: ${info}');
					// console.write('    ').write(label).write(': ').write(info).writeLine('');
				}
				Sys.println('    Script Info');
				// console.writeLine('').write('    ').writeLine('Script Info'.bold()).writeLine('');

				writeInfo('Title', info.title);
				writeInfo('Author', info.author);
				writeInfo('Pages', info.pages + '');
				writeInfo('Sections', info.sections.length + '');
				for (section in info.sections) {
					writeInfo('  ' + section.title, section.pages + ' pages');
				}
				// console.writeLine('');
				Sys.println('');

				return 0;
			});
	}

	/**
		Tools to compile a Panels script.
	**/
	@:defaultCommand
	public function documentation():Promise<Int> {
		// console.writeLine(getDocs());
		Sys.println(Cli.getDoc(this));
		return 0;
	}

	function getDefaultConfig():PanelsConfig {
		return {
			compiler: {
				startPage: 1,
				includeSections: includeSections,
				includePanelCount: includePanelCount
			},
			validator: {
				requireAuthor: requireAuthor,
				maxPanelsPerPage: maxPanelsPerPage,
				checkPanelOrder: checkPanelOrder
			}
		};
	}

	function createCompiler(config:PanelsConfig, source:Source):Compiler {
		return new Compiler(source, new VisualReporter(str -> Sys.println(str)), config);
		// return new Compiler(source, new VisualReporter(str -> console.writeLine(str)), config);
	}

	function getConfig(path:String):Future<PanelsConfig> {
		return if (ignoreDotPanels) {
			Sys.println('Ignoring .panels config -- using defaults and CLI flags');
			// console.writeLine('').writeLine('    Ignoring .panels config -- using defaults and CLI flags'.color(Yellow));
			getDefaultConfig();
		} else {
			DotPanels.find(fs.directory(path.directory()))
				.next(config -> {
					Sys.println('Using .panels config');
					config;
				})
					// .inspect(_ -> console.writeLine('').writeLine('    Using .panels config'.color(Yellow)))
				.recover(_ -> {
					Sys.println('No .panels config found -- using defaults and CLI flags');
					// console.writeLine('').writeLine('    No .panels config found -- using defaults and CLI flags'.color(Red));
					getDefaultConfig();
				});
		}
	}

	function getSource(file:String):Promise<Source> {
		if (file.extension() == '') file = file.withExtension('pan');

		return fs.entry(file)
			.next(entry -> entry.tryFile())
			.next(file -> file.read())
			.next(content -> ({
				file: file,
				content: content
			} : Source));
	}
}

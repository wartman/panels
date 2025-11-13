package panels.cli;

import kit.io.IoError;
import director.*;
import panels.generator.*;
import kit.io.FileSystem;

using haxe.io.Path;
using director.StyleTools;

/**
	Tools for compiling and investigating Panels scripts.
**/
class App implements Command {
	/**
		What file format to compile. Currently can be "odt" or "html".
	**/
	@:flag('f')
	public var format:String = 'odt';

	/**
		Where the compiled file should be saved. If left blank,
		Panels will save it next to the input file. 
	**/
	@:flag('d')
	public var destination:String = null;

	/**
		If true, Panels will output section titles in the compiled
		document.
	**/
	@:flag('s')
	public var includeSections:Bool = false;

	/**
		If true, Panels will output panel counts in the compiled
		document next to the page number (e.g. "Page 3 - 4 Panels").
	**/
	@:flag('p')
	public var includePanelCount:Bool = false;

	/**
		If true, Panels will fail to compile if the "Title: ..."
		property is not present in your script's header.
	**/
	@:flag('t')
	public var requireTitle:Bool = false;

	/**
		If true, Panels will fail to compile if the "Author: ..."
		property is not present in your script's header.
	**/
	@:flag('a')
	public var requireAuthor:Bool = false;

	/**
		If set, Panels will warn you if any of your pages have
		more than the allowed number of panels.
	**/
	@:flag('x')
	public var maxPanelsPerPage:Int = null;

	/**
		Makes sure that panel numbers are in order from lowest to highest.
	**/
	@:flag('o')
	public var checkPanelOrder:Bool = false;

	/**
		Ignores .panels configuration, if present.
	**/
	@:flag('i')
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
	public function compile(src:String):Task<Int> {
		var dest = destination != null ? destination : src.withoutExtension();

		if (format == null && dest.extension() != null) {
			format = dest.extension();
			dest = dest.withoutExtension();
		}

		return getSource(src).and(getConfig(src))
			.mapError(e -> e.toFailure())
			.then(pair -> createCompiler(pair.b, pair.a).compile().and(pair.b))
			.then(pair -> {
				pair.extract(try {a: node, b: config});

				var generator = switch format {
					case 'odt' | 'fodt': new OpenDocumentGenerator(config.compiler);
					case 'html': new HtmlGenerator(config.compiler);
					default: return Task.error(new Failure('Invalid format: $format'));
				}

				generator.save(fs, dest, node).mapError(e -> e.toFailure());
			})
			.then(_ -> {
				console.writeLine('')
					.write('    ')
					.write(' Success '.bold().backgroundColor(Yellow))
					.write(' Compiled ')
					.write(src.bold())
					.write(' to ')
					.writeLine(dest.withExtension(format).bold());
				return 0;
			});
	}

	/**
		Get information about your script (such as the current number of pages)
		without creating any output.
	**/
	@:command
	public function info(src:String):Task<Int> {
		return getSource(src).and(getConfig(src))
			.mapError(e -> e.toFailure())
			.then(pair -> createCompiler(pair.b, pair.a).compile().then(node -> Metadata.parse(node)))
			.then(info -> {
				function writeInfo(label:String, info:Null<String>) {
					if (info == null) {
						info = ' (not provided) '.bold().backgroundColor(Red);
					}
					console.write('    ').write(label).write(': ').write(info).writeLine('');
				}

				console.writeLine('').write('    ').writeLine('Script Info'.bold()).writeLine('');

				writeInfo('Title', info.title);
				writeInfo('Author', info.author);
				writeInfo('Pages', info.pages + '');
				writeInfo('Sections', info.sections.length + '');
				for (section in info.sections) {
					writeInfo('  ' + section.title, section.pages + ' pages');
				}
				console.writeLine('');

				return 0;
			});
	}

	/**
		Tools to compile a Panels script.
	**/
	@:defaultCommand
	public function documentation():Task<Int> {
		console.writeLine(getDocs());
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
		return new Compiler(source, new VisualReporter(str -> console.writeLine(str)), config);
	}

	function getConfig(path:String):Future<PanelsConfig> {
		return if (ignoreDotPanels) {
			console.writeLine('').writeLine('    Ignoring .panels config -- using defaults and CLI flags'.color(Yellow));
			Future.of(getDefaultConfig());
		} else {
			DotPanels.find(fs, path)
				.inspect(_ -> console.writeLine('').writeLine('    Using .panels config'.color(Yellow)))
				.recover(_ -> {
					console.writeLine('').writeLine('    No .panels config found -- using defaults and CLI flags'.color(Red));
					Future.of(getDefaultConfig());
				});
		}
	}

	function getSource(file:String):Task<Source, IoError> {
		if (file.extension() == '') file = file.withExtension('pan');

		return fs.detect(file)
			.then(entry -> entry.tryFile())
			.then(file -> file.read())
			.then(content -> ({
				file: file,
				content: content
			} : Source));
	}
}

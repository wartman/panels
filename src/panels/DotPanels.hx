package panels;

import haxe.Json;
import kit.io.Directory;
import kit.io.File;
import kit.io.FileSystem;
import kit.io.IoError;
import kit.io.Stat;
import panels.PanelsConfig;

using Reflect;
using haxe.io.Path;

class DotPanels {
	public static function find(path:String):Task<PanelsConfig, IoError> {
		return locateDotPanelsFile(FileSystem.ofCwd().directory(path.directory()))
			.then(pair -> switch pair {
				case {a: stat, b: file}:
					file.read().then(content -> ({
						file: stat.path,
						content: content
					} : Source));
			})
			.then(source -> new DotPanels(source).parse());
	}

	static function locateDotPanelsFile(dir:Directory):Task<Pair<Stat, File>, IoError> {
		return dir.detect('.panels').then(entry -> switch entry {
			case Empty(_):
				dir.detect('../').then(entry -> switch entry {
					case Directory(_, directory):
						locateDotPanelsFile(directory);
					default:
						Task.error(FileNotFound('.panels'));
				});
			case File(stat, file):
				return Task.ok(Pair.of(stat, file));
			default:
				Task.error(FileNotFound('.panels'));
		});
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
				includeFrontmatter: getOr(compiler, 'includeFrontmatter', true),
				includePanelCount: getOr(compiler, 'includePanelCount', false)
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

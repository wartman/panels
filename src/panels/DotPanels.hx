package panels;

import haxe.Json;
import doc.Directory;
import doc.File;
import doc.Stat;
import panels.PanelsConfig;

using Reflect;
using haxe.io.Path;

class DotPanels {
	public static function find(dir:Directory):Promise<PanelsConfig> {
		return locateDotPanelsFile(dir)
			.next(pair -> switch pair {
				case {a: stat, b: file}:
					file.read().next(content -> ({
						file: stat.path,
						content: content
					} : Source));
			})
			.next(source -> new DotPanels(source).parse());
	}

	static function locateDotPanelsFile(dir:Directory):Promise<Pair<Stat, File>> {
		return dir.entry('.panels').next(entry -> switch entry {
			case Missing(_):
				dir.entry('../').next(entry -> switch entry {
					case Directory(_, directory):
						locateDotPanelsFile(directory);
					default:
						new Error(NotFound, '.panels not found');
				});
			case File(stat, file):
				new Pair(stat, file);
			default:
				new Error(NotFound, '.panels not found');
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

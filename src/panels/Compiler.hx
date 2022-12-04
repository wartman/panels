package panels;

import js.html.Document;
import panels.Validator;
import panels.CompilerMetadata;

using tink.CoreApi;

class Compiler {
  final source:Source;
  final reporter:Reporter;
  final config:ValidatorConfig;
  final generator:Generator;

  public function new(source, reporter, generator, config) {
    this.source = source;
    this.reporter = reporter;
    this.generator = generator;
    this.config = config;
  }

  public function compile():Promise<String> {
    return compileToAst().next(generator.generate);
  }

  public function getMetadata():Promise<CompilerMetadata> {
    return compileToAst().next(node -> switch node.node {
      case Document(frontmatter, nodes):
        var currentSection:String = '(No section)';
        var pageCount:Int = 0;
        var sections:Array<SectionInfo> = [];

        for (node in nodes) switch node.node {
          case Section(title):
            if (pageCount > 0) {
              sections.push({
                title: currentSection,
                pages: pageCount
              });
            }
            currentSection = title;
            pageCount = 0;
          case Page(_):
            pageCount++;
          default:
        }

        if (pageCount > 0) {
          sections.push({
            title: currentSection,
            pages: pageCount
          });
        }

        ({
          title: frontmatter.get('title', null),
          author: frontmatter.get('author', null),
          pages: nodes.filter(n -> switch n.node {
            case Page(_): true;
            default: false;
          }).length,
          sections: sections
        } : CompilerMetadata);
      default:
        new Error(InternalError, 'Something went wrong');
    });
  }

  function compileToAst():Promise<Node> {
    try {
      var parser = new Parser(source);
      var node = parser.parse();
      var validator = new Validator(node, config);
      var errors = validator.validate();

      if (errors.length > 0) {
        for (e in errors) reporter.report(e, source);
        return new Error(InternalError, 'Failed to compile');
      }

      return node;
    } catch (e:ParserException) {
      reporter.report(e.toReporterMessage(), source);
      return new Error(InternalError, 'Failed to compile');
    }
  }
}

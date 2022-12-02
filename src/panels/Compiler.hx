package panels;

import panels.Validator;
import panels.generator.*;

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
    return compileToAst().next(node -> ({
      pages: switch node.node {
        case Document(_, nodes):
          nodes.filter(n -> switch n.node {
            case Page(_): true;
            default: false;
          }).length;
        default: 0;
      }
    } : CompilerMetadata));
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

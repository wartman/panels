package panels;

import panels.Reporter;

using Lambda;

typedef ValidatorConfig = {
  public final ?requireTitle:Bool;
  public final ?requireAuthor:Bool;
  public final ?requireProperties:Array<String>;
  public final ?maxPanelsPerPage:Int;
  public final ?maxWordsPerDialog:Int;
}

class Validator {
  final node:Node;
  final config:ValidatorConfig;

  public function new(node, config) {
    this.node = node;
    this.config = config;
  }

  public function validate() {
    return validateNode(node);
  }

  function validateNode(node:Node):Array<ReporterMessage> {
    var pageCount:Int = 0;
    return switch node.node {
      case Document(frontmatter, nodes):
        var warnings:Array<ReporterMessage> = [];

        if (config.requireTitle == true && frontmatter.get('title', null) == null) {
          warnings.push(createWarning('A title is required', node.pos));
        }

        if (config.requireAuthor == true && frontmatter.get('author', null) == null) {
          warnings.push(createWarning('An author is required', node.pos));
        }

        if (config.requireProperties != null) for (prop in config.requireProperties) {
          if (frontmatter.get(prop, null) == null) {
            warnings.push(createWarning('The required frontmatter property $prop was not found', node.pos));
          }
        }

        warnings.concat(nodes.map(validateNode).flatten());
      case Page(nodes):
        pageCount++;

        var panelCount = 0;
        var warnings:Array<ReporterMessage> = [];

        for (node in nodes) switch node.node {
          case Panel(type, nodes):
            panelCount++;
          // todo: check dialog length
          default:
        }
        if (config.maxPanelsPerPage != null && panelCount > config.maxPanelsPerPage) {
          warnings.push(createWarning('Page $pageCount has $panelCount panels, more than the alowed ${config.maxPanelsPerPage}', node.pos));
        }
        warnings;
      default:
        [];
    }
  }

  function createWarning(message:String, pos:Position):ReporterMessage {
    return {
      type: Warning,
      message: message,
      pos: pos
    };
  }
}

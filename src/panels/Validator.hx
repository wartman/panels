package panels;

import panels.Reporter;

using Lambda;

typedef ValidatorConfig = {
  public final ?requireTitle:Bool;
  public final ?requireAuthor:Bool;
  public final ?requireProperties:Array<String>;
  public final ?maxPanelsPerPage:Int;
  public final ?maxWordsPerDialog:Int;
  public final ?checkPanelOrder:Bool;
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
        var startPos:Position = {min: 0, max: 1, file: node.pos.file};
        var details = 'Make sure you have included all required properties'
          + ' in your document before the first line break (`---`). You can'
          + ' supress this warning by setting `config.requireTitle` or `config.requireAuthor`'
          + ' to false or by removing this property from `config.requireProperties`.';

        if (config.requireTitle == true && frontmatter.get('title', null) == null) {
          warnings.push(createWarning('A title is required', details, startPos));
        }

        if (config.requireAuthor == true && frontmatter.get('author', null) == null) {
          warnings.push(createWarning('An author is required', details, startPos));
        }

        if (config.requireProperties != null) for (prop in config.requireProperties) {
          if (frontmatter.get(prop, null) == null) {
            warnings.push(createWarning('The required frontmatter property $prop was not found', details, startPos));
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
            switch type {
              case UserDefined(number) if (config.checkPanelOrder != false):
                if (number != panelCount) {
                  warnings.push(createWarning(
                    'This panel number appears to be out of order',
                    'Note that you can omit a number in your panel declaration to have Panels generate one automatically.'
                    + ' If you intentionally are using panel numbers out of order, you can supress this warning'
                    + ' by setting `checkPanelOrder` to `false` in your config.',
                    node.pos));
                }
              default:
            }
          // @todo: check dialog length
          default:
        }
        if (config.maxPanelsPerPage != null && panelCount > config.maxPanelsPerPage) {
          warnings.push(createWarning('Page $pageCount has $panelCount panels, more than the allowed ${config.maxPanelsPerPage}', node.pos));
        }
        warnings;
      default:
        [];
    }
  }

  function createWarning(message:String, ?details:String, pos:Position):ReporterMessage {
    return {
      type: Warning,
      message: message,
      detailedMessage: details,
      pos: pos
    };
  }
}

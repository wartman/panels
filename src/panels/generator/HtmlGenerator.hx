package panels.generator;

import panels.NodeDef;
import panels.PanelsConfig;

using tink.CoreApi;

// @todo: This needs a lot of cleanup. Probably should use XML in here too.
class HtmlGenerator implements Generator {
  final config:CompilerConfig;

  var pageIsLeft:Bool = false;
  var pageNumber = 1;
  var panelNumber = 1;
  var panelCount = 0;

  public function new(config) {
    this.config = config;
  }

  public function generate(node:Node):Promise<String> {
    // @todo: fill in the <head> when we have frontmatter.
    var frontmatter:Frontmatter = switch node.node {
      case Document(frontmatter, _): frontmatter;
      default: [];
    }

    var title = frontmatter.get('title', '(Unnamed Comic)');
    var author = frontmatter.get('author', '(Unknown)');

    return '<!doctype HTML>
<html>
  <head>
    <title>$title</title>
  </head>

  <body>
    <style>
      body {
        font-family: sans-serif, "Helvetica Neue", arial;
        font-size: 15px;
      }

      .document {
        max-width: 700px;
        margin: 0 auto;
      }

      .section-header {
        margin: 0 0 20px 0;
        padding: 0 0 20px 0;
        border-bottom: 1px solid #000000;
      }

      .section-header h3 {
        margin: 0;
        padding: 0;
      }

      .page {
        margin: 0 0 20px 0;
        padding: 0 0 20px 0;
        border-bottom: 1px solid #cccccc;
      }

      .page:last-child {
        border-bottom: none;
      }

      .page-header {
        margin: 0 0 20px 0;
        text-decoration: underline;
        text-transform: uppercase;
      }

      .panel {
        margin: 0 0 20px 0;
        padding: 0 0 20px 0;
      }

      .panel-header {
        font-weight: bold;
        text-transform: uppercase;
      }

      .dialog {
        width: 400px;
        text-align: center; 
        margin: 0 auto 20px;
      }

      .dialog-sfx {
        font-style: italic;
      }

      .dialog-header-modifiers {
        margin-left: 10px;
      }

      .dialog-header-modifiers:before {
        content: "("
      }

      .dialog-header-modifiers:after {
        content: ")"
      }
    </style>
    <header class="comic-header page">
      <h1>$title</h1>
      <h2>By $author</h2>
    </header>
    ${generateNode(node)}
  </body>
</html>
';

  }

  function generateNode(node:Node) {
    return switch node.node {
      case Document(_, nodes):
        '<main class="document">' + nodes.map(generateNode).join('') + '</main>';
      case Text(content):
        switch content {
          case Normal(value): value;
          case Bold(value): '<b>$value</b>';
          case Italic(value): '<i>$value</i>';
          case Link(label, url): '<a href="$url">${generateNode(label)}</a>';
        }
      case Section(title) if (config.includeSections == true):
        '<header class="section-header"><h3>$title</h3></header>';
      case Section(_):
        '';
      case Paragraph(nodes) if (nodes.length == 0):
        '';
      case Paragraph(nodes):
        '<p>' + nodes.map(generateNode).join('') + '</p>';
      case Page(nodes):
        panelNumber = 1;
        panelCount = 0;
        var body = nodes.map(generateNode).join('');

        '<section class="page">'
        + '<header class="page-header">Page ${pageNumber++} - $panelCount Panels</header>'
        + body
        + '</section>';
      case Panel(type, nodes):
        panelCount++;

        var number = switch type {
          case Auto: panelNumber++;
          case UserDefined(number): number;
        }

        '<div class="panel">'
        + '<header class="panel-header" id="panel-$number">Panel $number</header>'
        + nodes.map(generateNode).join('')
        + '</div>';
      // @todo: SFX, CAPTIONs and normal dialog are pretty much the same -- DRY up a bit
      case Sfx(modifiers, content):
        '<div class="dialog dialog-sfx">'
        + '<header class="dialog-header">'
        + '<span class="dialog-header-speaker">SFX</span>'
        + (if (modifiers.length > 0) '<span class="dialog-header-modifiers">' + modifiers.map(generateNode).join(' ') + '</span>' else '')
        + '</header>'
        + '<div class="dialog-content">'
        + content.map(generateNode).join('')
        + '</div></div>';
      case Caption(modifiers, content):
        '<div class="dialog dialog-caption">'
        + '<header class="dialog-header">'
        + '<span class="dialog-header-speaker">CAPTION</span>'
        + (if (modifiers.length > 0) '<span class="dialog-header-modifiers">' + modifiers.map(generateNode).join(' ') + '</span>' else '')
        + '</header>'
        + '<div class="dialog-content">'
        + content.map(generateNode).join('')
        + '</div></div>';
      case Dialog(name, modifiers, content):
        '<div class="dialog">'
        + '<header class="dialog-header">'
        + '<span class="dialog-header-speaker">$name</span>'
        + (if (modifiers.length > 0) '<span class="dialog-header-modifiers">' + modifiers.map(generateNode).join(' ') + '</span>' else '')
        + '</header>'
        + '<div class="dialog-content">'
        + content.map(generateNode).join('')
        + '</div></div>';
    }
  }
}

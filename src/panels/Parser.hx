package panels;

import panels.NodeDef;

class Parser {
  final source:Source;
  var position = 0;

  public function new(source) {
    this.source = source;
  }

  public function parse():Node {
    var frontmatter = parseFrontmatter();
    var nodes:Array<Node> = [];

    while (!isAtEnd()) {
      nodes.push(parsePage());
    }

    return new Node(Document(frontmatter, nodes), createPos(0));
  }

  function parseFrontmatter():Array<FrontmatterProperty> {
    var props:Array<FrontmatterProperty> = [];

    ignoreComments();

    if (!checkProperty()) {
      return props;
    }

    while (!isAtEnd() && !checkPageBreak()) {
      spacesOrTabs();
      ignoreComments();
      var start = position;
      var key = property();
      spacesOrTabs();
      var value = readWhile(() -> !checkNewline());
      props.push({
        key: key,
        value: value,
        pos: createPos(start)
      });
      whitespace();
    }

    requirePageBreakOrEndOfFile();

    return props;
  }

  function checkProperty() {
    var prev = position;
    try {
      var prop = property();
      position = prev;
      return prop.length > 0;
    } catch (e:ParserException) {
      position = prev;
      return false;
    }
  }

  function property() {
    var prop = readWhile(() -> isAlphaNumeric(peek()) || '-' == peek() || '_' == peek());
    spacesOrTabs();
    consume(':');
    return prop;
  }

  function parsePage() {
    var start = position;
    var nodes:Array<Node> = [];

    whitespace();

    while (!isAtEnd() && !checkPageBreak()) {
      var panel = parsePanel();
      if (panel != null) {
        nodes.push(panel);
      }
    }

    whitespace();
    requirePageBreakOrEndOfFile();

    return new Node(Page(nodes), createPos(start));
  }

  function parsePanel() {
    var start = position;
    var type:PanelType = Auto;
    var nodes:Array<Node> = [];

    ignoreComments();

    consume('[',
      'Expected a panel-number declaration (either empty brackets `[]` or '
      + 'with a manually entered number (like `[1]`)). Note that every page '
      + 'requires at least one panel.');
    whitespace();
    if (isDigit(peek())) {
      type = UserDefined(number());
    }
    whitespace();
    consume(']');

    whitespace();

    while (!isAtEnd() && !checkPanelStart() && !checkPageBreak()) {
      spacesOrTabs();

      if (match('/*')) {
        comment();
        whitespace();
      } else if (caption()) {
        nodes.push(parseCaption());
      } else if (sfx()) {
        nodes.push(parseSfx());
      } else if (checkCharacterName()) {
        nodes.push(parseDialog());
      } else {
        nodes.push(parseParagraph());
        whitespace();
      }
    }

    return new Node(Panel(type, nodes), createPos(start));
  }

  function parseCaption() {
    var start = position;
    var content = dialogContent();
    return new Node(Caption(content.modifiers, content.nodes), createPos(start));
  }

  function parseSfx() {
    var start = position;
    var content = dialogContent();
    return new Node(Sfx(content.modifiers, content.nodes), createPos(start));
  }

  function parseDialog() {
    var start = position;
    var name = characterName();
    var content = dialogContent();
    return new Node(Dialog(name, content.modifiers, content.nodes), createPos(start));
  }

  function dialogContent():{modifiers:Array<Node>, nodes:Array<Node>} {
    spacesOrTabs();
    var modifiers = modifierList();
    spacesOrTabs();
    requireNewline();

    var nodes = dialogBody();

    return {
      modifiers: modifiers,
      nodes: nodes
    };
  }

  function modifierList() {
    var modifiers:Array<Node> = [];
    if (match('(')) {
      whitespace();
      while (!isAtEnd() && !check(')')) {
        modifiers.push(parseText(')'));
        whitespace();
      }
      consume(')');
    }
    return modifiers;
  }

  function dialogBody() {
    var nodes:Array<Node> = [];
    while (!isAtEnd() && !checkNewline()) {
      nodes.push(parseParagraph());
    }
    return nodes;
  }

  function parseParagraph() {
    var start = position;
    var nodes:Array<Node> = [];

    spacesOrTabs();
    if (matchCont()) {
      requireNewline();
      spacesOrTabs();
    }

    function process() {
      while (!isAtEnd() && !checkNewline()) {
        if (check('\\')) {
          parseText();
        } else if (match('[')) {
          nodes.push(parseLink());
        } else if (match('**')) {
          nodes.push(parseBold('**'));
        } else if (match('__')) {
          nodes.push(parseBold('__'));
        } else if (match('*')) {
          nodes.push(parseItalic('*'));
        } else if (match('_')) {
          nodes.push(parseItalic('_'));
        } else {
          nodes.push(parseText());
        }
      }
      var prev = position;
      if (newline()) {
        // Note: `whitespace()` will get newlines too, which we don't want
        spacesOrTabs();
        if (!checkNewline() && !checkPageBreak() && !checkCont()) {
          // Join text nodes with a space.
          nodes.push(new Node(Text(Normal(' ')), createPos(position)));
          process();
        } else if (!checkCont()) {
          position = prev;
        }
      }
    }

    process();

    return new Node(Paragraph(nodes), createPos(start));
  }

  function parseLink() {
    var start = position - 1;
    var label = parseText(']');
    if (!check('](')) {
      position = start + 1;
      return new Node(Text(Normal('[')), createPos(start));
    }
    consume(']');
    consume('(');
    var url = readText(() -> !check(')'));
    consume(')');
    return new Node(Text(Link(label, url)), createPos(start));
  }

  function parseBold(delimiter:String) {
    var start = position;
    var content = readText(() -> !check(delimiter));
    consume(delimiter);
    return new Node(Text(Bold(content)), createPos(start));
  }

  function parseItalic(delimiter:String) {
    var start = position;
    var content = readText(() -> !check(delimiter));
    consume(delimiter);
    return new Node(Text(Italic(content)), createPos(start));
  }

  function parseText(?delimiter:String) {
    var start = position;
    var delimiters = ['*', '_', '['];

    if (delimiter != null) {
      delimiters.push(delimiter);
    }

    var content = readText(() -> !checkAny(...delimiters));

    return new Node(Text(Normal(content)), createPos(start));
  }

  function readText(?doCheck:()->Bool) {
    var shouldLoop = if (doCheck == null)
      () -> !isAtEnd() && !checkNewline()
    else
      () -> !isAtEnd() && !checkNewline() && doCheck();
    var content = '';
    while (shouldLoop()) {
      if (check('\\')) {
        advance();
        content += advance();
      } else {
        content += advance();
      }
    }
    return content;
  }

  function checkPanelStart() {
    return check('[');
  }

  function checkPageBreak() {
    return check('---');
  }

  function checkCont() {
    return check('(cont.)');
  }

  function matchCont() {
    return match('(cont.)');
  }

  function pageBreak() {
    return match('---');
  }

  function requirePageBreakOrEndOfFile() {
    whitespace();
    if (!match('---') && !isAtEnd()) {
      throw new ParserException('Expected page break or end of file', null, createPos(position));
    }
  }

  function caption() {
    return match('CAPTION');
  }

  function sfx() {
    return match('SFX');
  }

  function checkCharacterName() {
    var start = position;
    var isName = characterName().length > 0;
    position = start;
    return isName;
  }

  function characterName() {
    var prev = position;
    var parts:Array<String> = [];

    function part() return readWhile(() -> isUcAlpha(peek()));

    parts.push(part());

    while (!isAtEnd()) {
      spacesOrTabs();

      if (isUcAlpha(peek())) {
        parts.push(part());
      } else if (check('(') || checkNewline()) {
        return parts.join(' ');
      } else {
        position = prev;
        return '';
      }
    }

    return parts.join(' ');
  }

  function comment(depth:Int = 0) {
    var content = readWhile(() -> !check('*/') && !check('/*'));
    if (match('/*')) return content + comment(depth + 1);
    consume('*/');
    if (depth > 0) return content + comment(depth - 1);
    return content;
  }

  function ignoreComments() {
    while (!isAtEnd() && match('/*')) {
      comment();
      whitespace();
    }
  }

  function checkNewline() {
    return checkAny('\r\n', '\n');
  }

  function newline() {
    return matchAny('\r\n', '\n');
  }

  function requireNewline() {
    return consumeAny('\r\n', '\n');
  }

  function isWhitespace(c:String) {
    return c == ' ' || c == '\n' || c == '\r' || c == '\t';
  }

  function spacesOrTabs() {
    return readWhile(() -> peek() == ' ' || peek() == '\t');
  }

  function whitespace() {
    return readWhile(() -> isWhitespace(peek()));
  }

  function number() {
    return Std.parseInt(readWhile(() -> isDigit(peek())));
  }

  function isDigit(c:String):Bool {
    return c >= '0' && c <= '9';
  }

  function isUcAlpha(c:String):Bool {
    return (c >= 'A' && c <= 'Z');
  }

  function isAlpha(c:String):Bool {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
  }

  function isAlphaNumeric(c:String) {
    return isAlpha(c) || isDigit(c);
  }

  function readWhile(compare:()->Bool):String {
    var out = [while (!isAtEnd() && compare()) advance()];
    return out.join('');
  }

  function match(value:String) {
    if (check(value)) {
      position = position
        + value.length;
      return true;
    }
    return false;
  }

  function matchAny(...values:String) {
    for (v in values.toArray()) {
      if (match(v)) return true;
    }
    return false;
  }

  function check(value:String) {
    var found = source.content.substr(position, value.length);
    return found == value;
  }

  function checkAny(...values:String) {
    for (v in values.toArray()) {
      if (check(v)) return true;
    }
    return false;
  }

  function consume(value:String, ?reason:String) {
    if (!match(value)) {
      throw new ParserException('Expected `${escapeForDisplay(value)}`', reason, createPos(position - value.length, position));
    }
  }

  function consumeAny(...values:String) {
    if (!matchAny(...values)) {
      throw new ParserException(values.toArray().map(escapeForDisplay).join(' or '), createPos(position - 1));
    }
  }

  function peek(?len:Int) {
    if (len != null) {
      return source.content.substr(position, len);
    }
    return source.content.charAt(position);
  }

  function advance() {
    if (!isAtEnd()) position++;
    return previous();
  }

  function previous() {
    return source.content.charAt(position
      - 1);
  }

  function isAtEnd() {
    return position == source.content.length;
  }

  function escapeForDisplay(s:String) {
    return switch s {
      case '\n': '<newline>';
      case '\r\n': '<windows-newline>';
      default: s;
    }
  }

  function createPos(min:Int, ?max:Int):Position {
    if (max == null) {
      max = position;
    }
    return {file: source.file, min: min, max: max};
  }
}

package panels;

import panels.NodeDef;

// @todo: Convert this to use Chars
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
      nodes.push(parseTopLevel());
    }

    return new Node(Document(frontmatter, nodes), createPos(0));
  }

  function parseTopLevel():Node {
    if (sectionBreak()) return parseSection();
    if (twoPageBreak()) return parsePage(true);
    if (pageBreak()) return parsePage();

    throw new ParserException('Expected a page break, a section break or the end of the file', null, createPos(position));
  }

  function parseFrontmatter():Array<FrontmatterProperty> {
    var props:Array<FrontmatterProperty> = [];

    ignoreComments();

    if (!checkProperty()) {
      return props;
    }

    while (!isAtEnd() && !checkPageOrSectionBreak()) {
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
      ignoreComments();
    }

    ignoreComments();

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

  function parseSection():Node {
    var start = position;

    whitespace();
    ignoreComments();

    if (isAtEnd() || checkPageOrSectionBreak()) {
      return new Node(Section(''), createPos(start));
    }

    var title = readText();

    whitespace();
    ignoreComments();

    return new Node(Section(title), createPos(start));
  }

  function parsePage(isTwoPager:Bool = false) {
    var start = position;
    var nodes:Array<Node> = [];

    whitespace();
    ignoreComments();

    while (!isAtEnd() && !checkPageOrSectionBreak()) {
      var panel = parsePanel();
      if (panel != null) {
        nodes.push(panel);
      }
    }

    whitespace();
    return new Node(isTwoPager ? TwoPage(nodes) : Page(nodes), createPos(start));
  }

  function parsePanel() {
    var type:PanelType = Auto;
    var nodes:Array<Node> = [];

    ignoreComments();

    var start = position;
    consume('[',
      'Expected a panel-number declaration (either empty brackets `[]` or '
      + 'a manually entered number (like `[1]`)). Note that every page '
      + 'requires at least one panel.');
    whitespace();
    if (isDigit(peek())) {
      type = UserDefined(number());
    }
    whitespace();
    consume(']');
    var declPos = createPos(start);

    whitespace();

    while (!isAtEnd() && !checkPanelStart() && !checkPageOrSectionBreak()) {
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
      } else if (aside()) {
        nodes.push(parseAside());
      } else {
        nodes.push(parseParagraph());
        whitespace();
      }
    }

    return new Node(Panel(type, nodes), declPos);
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

  function parseAside() {
    var start = position;
    var nodes:Array<Node> = [];
    var paragraph:Array<Node> = [];

    // @todo: This paragraph stuff is super clunky. Can we unify
    // it a bit more?

    function addParagraph() {
      var min = paragraph[0].pos.min;
      var max = paragraph[paragraph.length - 1].pos.max;
      nodes.push(new Node(Paragraph(paragraph), createPos(min, max)));
      paragraph = [];
    }

    function process() {
      while (!isAtEnd() && !checkNewline()) {
        paragraph.push(parseParagraphPart());
      }

      var prev = position;
      if (newline()) {
        spacesOrTabs();
        if (aside() && !checkNewline()) {
          nodes.push(new Node(Text(Normal(' ')), createPos(position)));
          process();
        } else if (newline()) {
          spacesOrTabs();
          if (aside()) {
            addParagraph();
            process();
          } else {
            position = prev;
          }
        } else {
          position = prev;
        }
      }
    }

    process();

    if (paragraph.length > 0) addParagraph();

    return new Node(Aside(nodes), createPos(start));
  }

  function dialogContent():{modifiers:Array<Node>, nodes:Array<Node>} {
    spacesOrTabs();
    var modifiers = modifierList();
    spacesOrTabs();
    requireNewline('A newline (`enter`) is required after a character name (plus modifers).');

    var nodes = dialogBody();

    return {
      modifiers: modifiers,
      nodes: nodes
    };
  }

  function modifierList() {
    var modifiers:Array<Node> = [];
    if (match('(')) {
      modifiers.push(parseText(')'));
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
    if (cont()) {
      requireNewline();
      spacesOrTabs();
    }

    function process() {
      while (!isAtEnd() && !checkNewline()) {
        nodes.push(parseParagraphPart());
      }
      var prev = position;
      if (newline()) {
        // Note: `whitespace()` will get newlines too, which we don't want
        spacesOrTabs();
        if (!checkNewline() && !checkPageOrSectionBreak() && !checkCont() && !checkAside()) {
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

  function parseParagraphPart() {
    if (check('\\')) {
      return parseText();
    } else if (match('[')) {
      return parseLink();
    } else if (match('**')) {
      return parseBold('**');
    } else if (match('__')) {
      return parseBold('__');
    } else if (match('*')) {
      return parseItalic('*');
    } else if (match('_')) {
      return parseItalic('_');
    } else {
      return parseText();
    }
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

  function checkPageOrSectionBreak() {
    return checkAny('---|---', '---', '===');
  }

  function checkCont() {
    return check('(cont.)');
  }

  function cont() {
    return match('(cont.)');
  }

  function sectionBreak() {
    return match('===');
  }

  function twoPageBreak() {
    return match('---|---');
  }

  function pageBreak() {
    return match('---');
  }

  function aside() {
    return match('>');
  }

  function checkAside() {
    return check('>');
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

    if (match('@')) {
      return readWhile(() -> !check('(') && !checkNewline());
    }

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

  function requireNewline(?reason:String) {
    return consumeAny(['\r\n', '\n'], reason);
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

  function consumeAny(values:Array<String>, ?reason:String) {
    if (!matchAny(...values)) {
      throw new ParserException(
        'Expected ' + values.map(escapeForDisplay).join(' or '), reason, createPos(position - 1));
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
    return source.content.charAt(position - 1);
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

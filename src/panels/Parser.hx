package panels;

// import haxe.ds.Option;
import panels.NodeDef;

// @todo: Comments
// @todo: Sub-paragraph stuff like links and text decoration.
// @todo: Escape sequences with the backslash (\)
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

    if (!checkProperty()) {
      return props;
    }

    while (!isAtEnd() && !checkPageBreak()) {
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

    consume('[');
    whitespace();
    if (isDigit(peek())) {
      type = UserDefined(number());
    }
    whitespace();
    consume(']');

    whitespace();

    while (!isAtEnd() && !checkPanelStart() && !checkPageBreak()) {
      spacesOrTabs();

      if (caption()) {
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
    spacesOrTabs();

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

    function process() {
      while (!isAtEnd() && !checkNewline()) {
        nodes.push(parseText());
      }
      var prev = position;
      if (newline()) {
        // Note: `whitespace()` will get newlines too, which we don't want
        spacesOrTabs();
        if (!newline() && !checkPageBreak()) {
          process();
        } else {
          position = prev;
        }
      }
    }

    process();

    return new Node(Paragraph(nodes), createPos(start));
  }

  function parseText(?delimiter:String) {
    var start = position;
    // @todo: We'll need to handle stuff like links and bold/italic soon.
    // Go look inside what we did for Boxup maybe?
    var content = readWhile(() -> {
      if (delimiter != null && peek() == delimiter)
        return false;
      return peek() != '\n' && peek(2) != '\r\n';
    });
    return new Node(Text(content), createPos(start));
  }

  function checkPanelStart() {
    return check('[');
  }

  function checkPageBreak() {
    return check('---');
  }

  function pageBreak() {
    return match('---');
  }

  function requirePageBreakOrEndOfFile() {
    whitespace();
    if (!match('---') && !isAtEnd()) {
      throw error('Expected end of file', position, position);
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

    function part()
      return readWhile(() -> isUcAlpha(peek()));

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

  // function attempt<T>(cb:() -> Option<T>):Option<T> {
  //   var start = position;
  //   return switch cb() {
  //     case Some(v):
  //       Some(v);
  //     case None:
  //       position = start;
  //       None;
  //   }
  // }

  function readWhile(compare:() -> Bool):String {
    var out = [while (!isAtEnd() && compare()) advance()];
    return out.join('');
  }

  function match(value:String) {
    if (check(value)) {
      position = position + value.length;
      return true;
    }
    return false;
  }

  function matchAny(...values:String) {
    for (v in values.toArray()) {
      if (match(v))
        return true;
    }
    return false;
  }

  function check(value:String) {
    var found = source.content.substr(position, value.length);
    return found == value;
  }

  function checkAny(...values:String) {
    for (v in values.toArray()) {
      if (check(v))
        return true;
    }
    return false;
  }

  function consume(value:String) {
    if (!match(value)) {
      throw expected(value);
    }
  }

  function consumeAny(...values:String) {
    if (!matchAny(...values)) {
      throw expected(values.toArray().map(escapeForDisplay).join(' or '));
    }
  }

  function peek(?len:Int) {
    if (len != null) {
      return source.content.substr(position, len);
    }
    return source.content.charAt(position);
  }

  function advance() {
    if (!isAtEnd())
      position++;
    return previous();
  }

  function previous() {
    return source.content.charAt(position - 1);
  }

  function isAtEnd() {
    return position == source.content.length;
  }

  function error(msg:String, min:Int, max:Int) {
    return new ParserException(msg, createPos(min, max));
  }

  function errorAt(msg:String, value:String) {
    return error(msg, position - value.length, position);
  }

  function reject(s:String) {
    return error('Unexpected `${escapeForDisplay(s)}`', position - s.length, position);
  }

  function expected(s:String) {
    return error('Expected `${escapeForDisplay(s)}`', position, position + 1);
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

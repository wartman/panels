package panels;

class VisualReporter implements Reporter {
  final print:(str:String)->Void;

  public function new(?print) {
    #if (sys || hxnodejs)
    this.print = print == null ? Sys.println : print;
    #else
    this.print = print == null ? str -> trace(str) : print;
    #end
  }

  public function report(e:ParserException, source:Source) {
    var pos = e.pos;
    var min = pos.min;
    var max = pos.max;
    var text = source.content.substring(min, max);
    var arrows = repeat(text.length, '^');

    while (min > 0) {
      switch source.content.charAt(--min) {
        case '\n':
          break;
        case t:
          text = t + text;
          arrows = ' ' + arrows;
      }
    }

    while (max <= source.content.length) {
      switch source.content.charAt(max++) {
        case '\n':
          break;
        case t:
          text += t;
      }
    }

    var line = source.content.substring(0, max).split('\n').length - 1; // why do we need to minus one?
    var textLines = text.split('\n');
    var start = 0;

    print('');
    print('ERROR: ${pos.file}:${line} [${pos.min} ${pos.max}]');
    for (t in textLines) {
      print(formatNumber(line++) + t);
      print(formatSpacer() + arrows.substr(start, t.length));
      start = t.length;
    }
    print(formatSpacer() + repeat(arrows.substr(0, start).length - 1) + e.message);
    if (e.detailedMessage != null) {
      print('');
      print(e.detailedMessage);
    }
    print('');
  }

  function formatNumber(lineNumber:Int) {
    var num = Std.string(lineNumber);
    var toAdd = 4 - num.length;
    return [for (_ in 0...(toAdd - 1)) ' '].join('') + '$num | ';
  }

  function formatSpacer() {
    return repeat(4) + '| ';
  }

  function repeat(len:Int, value:String = ' ') {
    if (len <= 0) return '';
    return [for (_ in 0...len) value].join('');
  }
}

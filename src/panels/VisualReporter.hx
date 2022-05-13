package panels;

import panels.Reporter;

class VisualReporter implements Reporter {
  final print:(str:String)->Void;

  public function new(?print) {
    #if (sys || hxnodejs)
    this.print = print == null ? Sys.println : print;
    #else
    this.print = print == null ? str -> trace(str) : print;
    #end
  }

  public function report(e:ReporterMessage, source:Source) {
    var pos = e.pos;
    var min = pos.min;
    var max = pos.max;
    var padding = 0;

    while (min > 0) {
      switch source.content.charAt(min) {
        case '\n':
          min++;
          break;
        default:
          min--;
      }
    }

    while (max <= source.content.length) {
      switch source.content.charAt(max) {
        case '\n':
          break;
        default:
          max++;
      }
    }

    var text = source.content.substring(min, max);
    var line = source.content.substring(0, max).split('\n').length;
    var textLines = text.split('\n');
    var totalLines = textLines.length;
    var linesWritten = 0;
    var placeholderWritten = false;
    var firstLine = line - (textLines.length - 1);
    var start = 0;
    var underline = switch e.type {
      case Warning: '~';
      case Error: '^';
    }

    switch e.type {
      case Error:
        print('');
        print('ERROR: ${pos.file}:${firstLine} [${pos.min} ${pos.max}]');
      case Warning:
        print('');
        print('WARNING: ${pos.file}:${firstLine} [${pos.min} ${pos.max}]');
    }

    for (t in textLines) {
      linesWritten++;

      var currentLine = firstLine++;

      if ((totalLines > 6 && (linesWritten <= 3 || (linesWritten >= totalLines - 3))) || totalLines < 6) {
        print(formatNumber(currentLine) + t);
        if (min < pos.min) {
          if (min + t.length > pos.min) {
            var space = pos.min - min;
            padding = space;
            print(formatSpacer() + repeat(space) + repeatAtLeastOnce(t.length - space, underline));
          }
        } else {
          print(formatSpacer() + repeatAtLeastOnce(t.length, underline));
        }
      } else if (!placeholderWritten) {
        placeholderWritten = true;
        print('');
        print(formatBreakpoint());
        print('');
      }

      min += t.length;
      start = t.length;
    }

    print(formatSpacer() + repeat(padding) + e.message);

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

  function formatBreakpoint() {
    return repeat(4) + '...';
  }

  function repeatAtLeastOnce(len:Int, value:String = ' ') {
    if (len <= 0) return repeat(1, value);
    return repeat(len, value);
  }

  function repeat(len:Int, value:String = ' ') {
    if (len <= 0) return '';
    return [for (_ in 0...len) value].join('');
  }
}

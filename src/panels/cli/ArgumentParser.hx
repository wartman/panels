package panels.cli;

using Lambda;
using StringTools;

class ArgumentParser {
  final args:Array<String>;
  var pos = 0;

  public function new(args) {
    this.args = args;
  }

  public function parse():AppArgs {
    pos = 0;

    var source = parseArg();
    var fields = [while (pos < args.length) parseNamedArg()];

    return {
      source: source,
      format: getArg(fields, 'f', 'format'),
      output: getArg(fields, 'o', 'output'),
      requireTitle: getArg(fields, null, 'requireTitle') == 'true',
      requireAuthor: getArg(fields, null, 'requireAuthor') == 'true',
      checkPanelOrder: getArg(fields, null, 'checkPanelOrder') == 'true',
      maxPanelsPerPage: {
        var value = getArg(fields, null, 'maxPanelsPerPage');
        if (value != null) Std.parseInt(value) else
          null;
      },
      maxWordsPerDialog: {
        var value = getArg(fields, null, 'maxWordsPerDialog');
        if (value != null) Std.parseInt(value) else
          null;
      }
    };
  }

  function parseArg() {
    var arg = args[pos++];
    if (arg.startsWith('--') || (arg.startsWith('-') && arg.length == 2)) {
      throw 'Expected a parameter.';
    }
    return arg;
  }

  function parseNamedArg():{name:String, value:String} {
    var name = args[pos++];
    var value = args[pos++];

    if (name == null || !name.startsWith('-')) {
      throw 'Invalid arg name';
    }

    if (value == null) {
      throw 'Invalid value';
    }

    return {name: name, value: value};
  }

  function getArg(args:Array<{name:String, value:String}>, short:Null<String>, long:String, isOptional = true) {
    var arg = if (short == null) args.find(n -> n.name == '--$long') else args.find(n -> n.name == '--$long' || n.name == '-$short');
    if (arg == null && !isOptional) {
      throw 'Required property $arg was not provided';
    }
    return arg == null ? null : arg.value;
  }
}

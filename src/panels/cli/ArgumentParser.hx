package panels.cli;

using Lambda;
using StringTools;

// @todo: Clean this up.
class ArgumentParser {
  final args:Array<String>;
  var pos = 0;

  public function new(args) {
    this.args = args;
  }

  public function parse():AppArgs {
    pos = 0;

    var source = parseArg();
    var args = [while (pos < args.length) parseNamedArg()];

    for (arg in args) validateArg(arg);

    return {
      source: source,
      format: getArg(args, 'f', 'format'),
      output: getArg(args, 'o', 'output'),
      requireTitle: getArg(args, null, 'requireTitle') == 'true',
      requireAuthor: getArg(args, null, 'requireAuthor') == 'true',
      checkPanelOrder: getArg(args, null, 'checkPanelOrder') != 'false',
      maxPanelsPerPage: {
        var value = getArg(args, null, 'maxPanelsPerPage');
        if (value != null) Std.parseInt(value) else
          null;
      },
      maxWordsPerDialog: {
        var value = getArg(args, null, 'maxWordsPerDialog');
        if (value != null) Std.parseInt(value) else
          null;
      }
    };
  }

  static final allowed = [
    'f',
    'format',
    'o',
    'output',
    'requireTitle',
    'requireAuthor',
    'maxPanelsPerPage',
    'maxWordsPerDialog'
  ];

  function validateArg(arg:{name:String, value:String}) {
    if (!allowed.contains(arg.name)) {
      throw 'Invalid argument: ${arg.name}';
    }
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

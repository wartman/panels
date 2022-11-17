package panels.cli;

import cmdr.*;

class App extends Command {
  @:command final generate:GenerateCommand = new GenerateCommand();
  @:command final count:PageCountCommand = new PageCountCommand();

  public function new() {}

  public function getDescription():Null<String> {
    return 'The entrypoint for Panels';
  }

  function process(input:Input, output:Output):ExitCode {
    return Success;
  }
}

import tink.Cli;
import panels.cli.*;

// import cmdr.input.SysInput;
// import cmdr.output.SysOutput;
function main() {
  // var app = new App();
  // app.execute(new SysInput(), new SysOutput());
  Cli.process(Sys.args(), new App()).handle(Cli.exit);
}

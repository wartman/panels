import panels.cli.*;

function main() {
  var args = new ArgumentParser(Sys.args());
  var app = new App(args.parse());
  app.process();
}

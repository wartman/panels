import Doc;
import tink.Cli;
import panels.cli.*;

function main() {
	Cli.process(Sys.args(), new App(FileSystem.ofCwd())).handle(Cli.exit);
}

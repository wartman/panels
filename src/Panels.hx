import Director;
import kit.io.FileSystem;
import panels.cli.*;

function main() {
	Director.fromSys().execute(new App(FileSystem.ofCwd()));
}

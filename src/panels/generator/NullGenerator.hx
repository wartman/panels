package panels.generator;

import kit.io.*;

class NullGenerator implements Generator {
	public function new() {}

	public function generate(node:Node):Task<String> {
		return '';
	}

	public function save(fs:FileSystem, path:String, node:Node):Task<Nothing, IoError> {
		return Task.nothing();
	}
}

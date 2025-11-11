package panels;

import kit.io.FileSystem;
import kit.io.IoError;

interface Generator {
	public function generate(node:Node):Task<String>;
	public function save(fs:FileSystem, path:String, node:Node):Task<Nothing, IoError>;
}

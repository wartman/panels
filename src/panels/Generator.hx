package panels;

import doc.FileSystem;

interface Generator {
	public function generate(node:Node):Promise<String>;
	public function save(fs:FileSystem, path:String, node:Node):Promise<Noise>;
}

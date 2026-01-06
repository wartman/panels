package panels.generator;

class NullGenerator implements Generator {
	public function new() {}

	public function generate(node:Node):Promise<String> {
		return '';
	}

	public function save(fs:FileSystem, path:String, node:Node):Promise<Noise> {
		return Noise;
	}
}

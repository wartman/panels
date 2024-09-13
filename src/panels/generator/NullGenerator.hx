package panels.generator;

class NullGenerator implements Generator {
  public function new() {}

  public function generate(node:Node):Task<String> {
    return '';
  }
}

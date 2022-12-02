package panels.generator;

using tink.CoreApi;

class NullGenerator implements Generator {
  public function new() {}

  public function generate(node:Node):Promise<String> {
    return '';
  }
}

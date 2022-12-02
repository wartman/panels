package panels;

using tink.CoreApi;

interface Generator {
  public function generate(node:Node):Promise<String>;
}

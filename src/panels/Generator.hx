package panels;

interface Generator {
  public function generate(node:Node):Task<String>;
}

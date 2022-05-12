package panels;

class Node {
  public final node:NodeDef;
  public final pos:Position;

  public function new(node, pos) {
    this.node = node;
    this.pos = pos;
  }
}

package panels;

import haxe.Exception;

class ParserException extends Exception {
  public final pos:Position;

  public function new(message, pos) {
    super(message);
    this.pos = pos;
  }
}

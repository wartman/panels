package panels;

import haxe.Exception;

class ParserException extends Exception {
  public final detailedMessage:Null<String>;
  public final pos:Position;

  public function new(message, ?detailedMessage, pos) {
    super(message);
    this.detailedMessage = detailedMessage;
    this.pos = pos;
  }
}

package panels;

import haxe.Exception;
import panels.Reporter;

class ParserException extends Exception {
  public final detailedMessage:Null<String>;
  public final pos:Position;

  public function new(message, ?detailedMessage, pos) {
    super(message);
    this.detailedMessage = detailedMessage;
    this.pos = pos;
  }

  public function toReporterMessage():ReporterMessage {
    return {
      type: Error,
      message: message,
      detailedMessage: detailedMessage,
      pos: pos
    }
  }
}

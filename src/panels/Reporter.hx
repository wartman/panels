package panels;

enum ReporterMessageType {
  Warning;
  Error;
}

typedef ReporterMessage = {
  public final type:ReporterMessageType;
  public final message:String;
  public final ?detailedMessage:String;
  public final pos:Position;
}

interface Reporter {
  public function report(message:ReporterMessage, source:Source):Void;
}

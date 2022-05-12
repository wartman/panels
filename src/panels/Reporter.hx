package panels;

interface Reporter {
  public function report(exception:ParserException, source:Source):Void;
}

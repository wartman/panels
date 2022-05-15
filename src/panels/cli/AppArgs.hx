package panels.cli;

import panels.Validator;

typedef AppArgs = ValidatorConfig & {
  public final source:String;
  public final ?format:String;
  public final ?output:String;
}

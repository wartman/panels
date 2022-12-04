package panels;

@:forward
abstract PanelsConfig(PanelsConfigImpl) from PanelsConfigImpl to PanelsConfigImpl {
  public function new(config) {
    this = config;
  }

  public function withOverrides() {}
}

typedef PanelsConfigImpl = {
  public final compiler:CompilerConfig;
  public final validator:ValidatorConfig;
}

typedef CompilerConfig = {
  public final ?includeSections:Bool;
  public final ?includeFrontmatter:Bool;
  // @todo: Add more
}

typedef ValidatorConfig = {
  public final ?requireTitle:Bool;
  public final ?requireAuthor:Bool;
  // public final ?requireProperties:Array<String>;
  public final ?maxPanelsPerPage:Int;
  public final ?maxWordsPerDialog:Int;
  public final ?checkPanelOrder:Bool;
}

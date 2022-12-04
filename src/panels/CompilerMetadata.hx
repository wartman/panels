package panels;

typedef CompilerMetadata = {
  public final title:Null<String>;
  public final author:Null<String>;
  public final pages:Int;
  public final sections:Array<SectionInfo>;
}

typedef SectionInfo = {
  public final title:String;
  public final pages:Int;
}

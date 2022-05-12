package panels;

using Lambda;
using StringTools;

enum PanelType {
  Auto;
  UserDefined(number:Int);
}

typedef FrontmatterProperty = {
  public final key:String;
  public final value:String;
  public final pos:Position;
}

abstract Frontmatter(Array<FrontmatterProperty>) from Array<FrontmatterProperty> {
  public function new(matter) {
    this = matter;
  }

  public function get(key:String, ?def:String) {
    var prop = this.find(p -> p.key.toLowerCase() == key.toLowerCase());
    if (prop == null) {
      return def;
    }
    return prop.value;
  }
}

enum NodeDef {
  Document(frontmatter:Frontmatter, nodes:Array<Node>);
  Text(content:String);
  Paragraph(nodes:Array<Node>);
  Page(nodes:Array<Node>);
  Panel(type:PanelType, nodes:Array<Node>);
  Dialog(name:String, modifiers:Array<Node>, content:Array<Node>);
  Sfx(modifiers:Array<Node>, content:Array<Node>);
  Caption(modifiers:Array<Node>, content:Array<Node>);
}
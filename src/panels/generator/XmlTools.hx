package panels.generator;

class XmlTools {
  public static function append(node:Xml, child:Xml) {
    switch child.nodeType {
      case Document: for (el in child.elements()) node.addChild(el);
      default: node.addChild(child);
    }
    return node;
  }
}

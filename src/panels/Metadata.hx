package panels;

using Lambda;

@:forward
abstract Metadata(MetadataObject) from MetadataObject {
  public static function parse(node:Node):Result<Metadata> {
    return switch node.node {
      case Document(frontmatter, nodes):
        var currentSection:String = '(No section)';
        var pageCount:Int = 0;
        var sections:Array<SectionInfo> = [];

        for (node in nodes) switch node.node {
          case Section(title):
            if (pageCount > 0) {
              sections.push({
                title: currentSection,
                pages: pageCount
              });
            }
            currentSection = title;
            pageCount = 0;
          case Page(_):
            pageCount++;
          case TwoPage(_):
            pageCount += 2;
          default:
        }

        if (pageCount > 0) {
          sections.push({
            title: currentSection,
            pages: pageCount
          });
        }

        Ok(new Metadata({
          title: frontmatter.get('title', null),
          author: frontmatter.get('author', null),
          pages: nodes.map(node -> switch node.node {
            case Page(_): 1;
            case TwoPage(_): 2;
            default: 0;
          }).fold((item, count) -> item + count, 0),
          sections: sections
        }));
      default:
        Error('Something went wrong');
    }
  }

  public function new(object) {
    this = object;
  }
}

typedef MetadataObject = {
  public final title:Null<String>;
  public final author:Null<String>;
  public final pages:Int;
  public final sections:Array<SectionInfo>;
}

typedef SectionInfo = {
  public final title:String;
  public final pages:Int;
}

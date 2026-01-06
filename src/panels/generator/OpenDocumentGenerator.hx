package panels.generator;

import Xml;
import doc.FileSystem;
import panels.NodeDef;
import panels.PanelsConfig;

using haxe.io.Path;
using panels.generator.XmlTools;
using StringTools;

typedef OpenDocumentGeneratorContext = {
	public var currentPage:Int;
	public var currentPanel:Int;
}

// @note: This is a bit of a mess -- I just want something that mostly works.
// @see: https://docs.oasis-open.org/office/v1.2/os/OpenDocument-v1.2-os-part1.html#__RefHeading__440346_826425813
class OpenDocumentGenerator implements Generator {
	final config:CompilerConfig;

	public function new(config) {
		this.config = config;
	}

	public function save(fs:FileSystem, path:String, node:Node):Promise<Noise> {
		return generate(node)
			.next(contents -> fs
				.entry(path.directory())
				.next(entry -> entry.ensureDirectory())
				.next(dir -> dir.file(path.withoutDirectory().withExtension('fodt')).write(contents))
			)
			.next(_ -> Noise);
	}

	public function generate(node:Node):Promise<String> {
		var doc = Xml.createDocument();
		doc.addChild(Xml.parse('<?xml version="1.0" encoding="UTF-8"?>'));
		doc.addChild(generateNode(node, {
			currentPage: (config.startPage ?? 1) - 1,
			currentPanel: 0
		}));

		return haxe.xml.Printer.print(doc);
	}

	function generateNode(node:Node, context:OpenDocumentGeneratorContext):Xml {
		return switch node.node {
			case Document(frontmatter, nodes):
				generateDocument(frontmatter, nodes, context);
			case Section(_):
				fragment([]);
			case Page(nodes):
				generatePage(nodes, context);
			case TwoPage(nodes):
				generatePage(nodes, context, true);
			case Text(content):
				generateText(content);
			case Panel(type, nodes):
				generatePanel(type, nodes, context);
			case Dialog(name, modifiers, content):
				generateDialog(name, modifiers, content, context);
			case Sfx(modifiers, content):
				generateDialog('SFX', modifiers, content, context);
			case Caption(modifiers, content):
				generateDialog('CAPTION', modifiers, content, context);
			case Aside(nodes):
				generateAside(nodes, context);
			case Paragraph(nodes):
				p([], nodes.map(n -> generateNode(n, context)));
		}
	}

	function generateDocument(frontmatter:Frontmatter, nodes:Array<Node>, context):Xml {
		// var doc = Xml.createElement('office:document');
		// doc.set('xmlns:office', 'urn:oasis:names:tc:opendocument:xmlns:office:1.0');
		// doc.set('office:mimetype', 'application/vnd.oasis.opendocument.text');
		// doc.set('office:version', '1.3');
		var doc = parseXml('<office:document
      xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
      xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" 
      xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" 
      xmlns:ooo="http://openoffice.org/2004/office" 
      xmlns:xlink="http://www.w3.org/1999/xlink" 
      xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" 
      xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0" 
      xmlns:dc="http://purl.org/dc/elements/1.1/" 
      xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" 
      xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" 
      xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" 
      xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
      xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
      xmlns:rpt="http://openoffice.org/2005/report" 
      xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" 
      xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" 
      xmlns:ooow="http://openoffice.org/2004/writer" 
      xmlns:oooc="http://openoffice.org/2004/calc" 
      xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2"
      xmlns:tableooo="http://openoffice.org/2009/table" 
      xmlns:calcext="urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0"
      xmlns:drawooo="http://openoffice.org/2010/draw"
      xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0"
      xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
      xmlns:math="http://www.w3.org/1998/Math/MathML"
      xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
      xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
      xmlns:dom="http://www.w3.org/2001/xml-events"
      xmlns:xforms="http://www.w3.org/2002/xforms"
      xmlns:xsd="http://www.w3.org/2001/XMLSchema"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:formx="urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:form:1.0"
      xmlns:xhtml="http://www.w3.org/1999/xhtml"
      xmlns:grddl="http://www.w3.org/2003/g/data-view#"
      xmlns:css3t="http://www.w3.org/TR/css3-text/"
      xmlns:officeooo="http://openoffice.org/2009/office"
      office:version="1.3"
      office:mimetype="application/vnd.oasis.opendocument.text"
    />').firstChild();
		doc.append(parseXml('<office:automatic-styles>
      <style:style style:name="P1" style:family="paragraph" style:parent-style-name="Standard">
      <style:text-properties officeooo:rsid="000993cf" officeooo:paragraph-rsid="000993cf"/>
      </style:style>
      <style:style style:name="P2" style:family="paragraph" style:parent-style-name="Standard">
      <style:text-properties fo:font-weight="bold" officeooo:rsid="000993cf" officeooo:paragraph-rsid="000993cf" style:font-weight-asian="bold" style:font-weight-complex="bold"/>
      </style:style>
      <style:style style:name="P3" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:text-properties officeooo:paragraph-rsid="000993cf"/>
      </style:style>
      <style:style style:name="P4" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0in" style:contextual-spacing="false" fo:line-height="138%" fo:text-align="center" style:justify-single-word="false" style:writing-mode="lr-tb"/>
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:font-name="Arial" fo:font-size="11pt" fo:font-style="normal" style:text-underline-style="solid" style:text-underline-width="auto" style:text-underline-color="font-color" fo:font-weight="normal" fo:background-color="transparent"/>
      </style:style>
      <style:style style:name="P5" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0in" style:contextual-spacing="false" fo:line-height="138%" style:writing-mode="lr-tb"/>
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Arial" fo:font-size="11pt" fo:font-style="normal" style:text-underline-style="none" fo:font-weight="bold" style:text-blinking="false" fo:background-color="transparent"/>
      </style:style>
      <style:style style:name="P6" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0in" style:contextual-spacing="false" fo:line-height="138%" style:writing-mode="lr-tb"/>
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Arial" fo:font-size="11pt" fo:font-style="normal" style:text-underline-style="none" fo:font-weight="normal" style:text-blinking="false" fo:background-color="transparent"/>
      </style:style>
      <style:style style:name="P7" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0in" style:contextual-spacing="false" fo:line-height="138%" fo:text-align="center" style:justify-single-word="false" style:writing-mode="lr-tb"/>
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Arial" fo:font-size="11pt" fo:font-style="normal" style:text-underline-style="none" fo:font-weight="normal" style:text-blinking="false" fo:background-color="transparent"/>
      </style:style>
      <style:style style:name="P8" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0in" style:contextual-spacing="false" fo:line-height="138%" style:writing-mode="lr-tb"/>
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Arial" fo:font-size="11pt" fo:font-style="italic" style:text-underline-style="none" fo:font-weight="normal" style:text-blinking="false" fo:background-color="transparent"/>
      </style:style>
      <style:style style:name="P9" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0in" style:contextual-spacing="false" fo:line-height="138%" fo:text-align="center" style:justify-single-word="false" style:writing-mode="lr-tb"/>
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Arial" fo:font-size="11pt" fo:font-style="italic" style:text-underline-style="none" fo:font-weight="normal" style:text-blinking="false" fo:background-color="transparent"/>
      </style:style>
      <style:style style:name="P10" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0in" style:contextual-spacing="false" fo:line-height="138%" style:writing-mode="lr-tb"/>
      </style:style>
      <style:style style:name="P11" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:break-before="page"/>
      </style:style>
      <style:style style:name="P12" style:family="paragraph" style:parent-style-name="Text_20_body">
      <style:paragraph-properties fo:break-before="page"/>
      <style:text-properties officeooo:paragraph-rsid="000993cf"/>
      </style:style>
      <style:style style:name="T1" style:family="text">
      <style:text-properties officeooo:rsid="000993cf"/>
      </style:style>
      <style:style style:name="T2" style:family="text">
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none"  fo:font-style="normal" style:text-underline-style="none" fo:font-weight="normal" style:text-blinking="false" fo:background-color="transparent" loext:char-shading-value="0"/>
      </style:style>
      <style:style style:name="T3" style:family="text">
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Arial" fo:font-size="11pt" fo:font-style="normal" style:text-underline-style="none" fo:font-weight="bold" style:text-blinking="false" fo:background-color="transparent" loext:char-shading-value="0"/>
      </style:style>
      <style:style style:name="T4" style:family="text">
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Arial" fo:font-size="11pt" fo:font-style="normal" style:text-underline-style="none" fo:font-weight="normal" style:text-blinking="false" fo:background-color="transparent" loext:char-shading-value="0"/>
      </style:style>
      <style:style style:name="T5" style:family="text">
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Arial" fo:font-size="11pt" fo:font-style="italic" style:text-underline-style="none" fo:font-weight="normal" style:text-blinking="false" fo:background-color="transparent" loext:char-shading-value="0"/>
      </style:style>
      <style:style style:name="T6" style:family="text">
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:text-underline-style="none" style:text-blinking="false" fo:background-color="transparent" loext:char-shading-value="0"/>
      </style:style>
      <style:style style:name="T7" style:family="text">
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:font-name="Arial" fo:font-size="14pt" fo:font-style="normal" style:text-underline-style="solid" style:text-underline-width="auto" style:text-underline-color="font-color" fo:font-weight="normal" fo:background-color="transparent" loext:char-shading-value="0"/>
      </style:style>
      <style:style style:name="T8" style:family="text">
      <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-underline-style="solid" style:text-underline-width="auto" style:text-underline-color="font-color" fo:background-color="transparent" loext:char-shading-value="0"/>
      </style:style>
      <style:page-layout style:name="pm1">
      <style:page-layout-properties fo:page-width="8.5in" fo:page-height="11in" style:num-format="1" style:print-orientation="portrait" fo:margin-top="0.7874in" fo:margin-bottom="0.7874in" fo:margin-left="0.7874in" fo:margin-right="0.7874in" style:writing-mode="lr-tb" style:layout-grid-color="#c0c0c0" style:layout-grid-lines="20" style:layout-grid-base-height="0.278in" style:layout-grid-ruby-height="0.139in" style:layout-grid-mode="none" style:layout-grid-ruby-below="false" style:layout-grid-print="false" style:layout-grid-display="false" style:footnote-max-height="0in">
        <style:footnote-sep style:width="0.0071in" style:distance-before-sep="0.0398in" style:distance-after-sep="0.0398in" style:line-style="solid" style:adjustment="left" style:rel-width="25%" style:color="#000000"/>
      </style:page-layout-properties>
      <style:header-style/>
      <style:footer-style/>
      </style:page-layout>
    </office:automatic-styles>'));
		doc.append(parseXml('<office:styles>
      <style:default-style style:family="graphic">
      <style:graphic-properties svg:stroke-color="#3465a4" draw:fill-color="#729fcf" fo:wrap-option="no-wrap" draw:shadow-offset-x="0.1181in" draw:shadow-offset-y="0.1181in" draw:start-line-spacing-horizontal="0.1114in" draw:start-line-spacing-vertical="0.1114in" draw:end-line-spacing-horizontal="0.1114in" draw:end-line-spacing-vertical="0.1114in" style:flow-with-text="false"/>
      <style:paragraph-properties style:text-autospace="ideograph-alpha" style:line-break="strict" style:font-independent-line-spacing="false">
        <style:tab-stops/>
      </style:paragraph-properties>
      <style:text-properties style:use-window-font-color="true" loext:opacity="0%" style:font-name="Liberation Serif" fo:font-size="12pt" fo:language="en" fo:country="US" style:letter-kerning="true" style:font-name-asian="NSimSun" style:font-size-asian="10.5pt" style:language-asian="zh" style:country-asian="CN" style:font-name-complex="Lucida Sans" style:font-size-complex="12pt" style:language-complex="hi" style:country-complex="IN"/>
      </style:default-style>
      <style:default-style style:family="paragraph">
      <style:paragraph-properties fo:orphans="2" fo:widows="2" fo:hyphenation-ladder-count="no-limit" style:text-autospace="ideograph-alpha" style:punctuation-wrap="hanging" style:line-break="strict" style:tab-stop-distance="0.4925in" style:writing-mode="page"/>
      <style:text-properties style:use-window-font-color="true" loext:opacity="0%" style:font-name="Liberation Serif" fo:font-size="12pt" fo:language="en" fo:country="US" style:letter-kerning="true" style:font-name-asian="NSimSun" style:font-size-asian="10.5pt" style:language-asian="zh" style:country-asian="CN" style:font-name-complex="Lucida Sans" style:font-size-complex="12pt" style:language-complex="hi" style:country-complex="IN" fo:hyphenate="false" fo:hyphenation-remain-char-count="2" fo:hyphenation-push-char-count="2" loext:hyphenation-no-caps="false"/>
      </style:default-style>
      <style:default-style style:family="table">
      <style:table-properties table:border-model="collapsing"/>
      </style:default-style>
      <style:default-style style:family="table-row">
      <style:table-row-properties fo:keep-together="auto"/>
      </style:default-style>
      <style:style style:name="Standard" style:family="paragraph" style:class="text"/>
      <style:style style:name="Text_20_body" style:display-name="Text body" style:family="paragraph" style:parent-style-name="Standard" style:class="text">
        <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0.0972in" style:contextual-spacing="false" fo:line-height="115%"/>
      </style:style>
      <style:style style:name="PBASE" style:display-name="Panels: Base styles" style:parent-style-name="Text_20_body" style:family="paragraph">
        <style:text-properties fo:font-variant="normal" fo:text-transform="none" fo:color="#000000" loext:opacity="100%" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Courier" fo:font-family="Courier" fo:font-size="11pt" fo:font-style="normal" style:text-underline-style="none" fo:font-weight="normal" style:text-blinking="false" fo:background-color="transparent"/>
      </style:style>
      <style:style style:name="PI" style:display-name="Panels: Italic" style:parent-style-name="Text_20_body" style:family="text">
        <style:text-properties fo:font-style="italic" />
      </style:style>
      <style:style style:name="PB" style:display-name="Panels: Bold" style:parent-style-name="Text_20_body" style:family="text">
        <style:text-properties fo:font-weight="bold" />
      </style:style>
      <style:style style:name="PTITLE" style:display-name="Panels: Title" style:parent-style-name="PBASE" style:family="paragraph">
        <style:paragraph-properties fo:margin-top="0in" fo:margin-bottom="0.4in" style:contextual-spacing="false"/>
        <style:text-properties fo:text-transform="uppercase" fo:font-size="14pt" style:text-underline-style="solid" style:text-underline-width="auto" style:text-underline-color="font-color"/>
      </style:style>
      <style:style style:name="PPANEL" style:display-name="Panels: Panel Title" style:parent-style-name="PBASE" style:family="paragraph">
        <style:text-properties fo:text-transform="uppercase" fo:font-weight="bold" />
      </style:style>
      <style:style style:name="PPAGEBREAK" style:display-name="Panels: Page Break" style:parent-style-name="Standard" style:family="paragraph">
        <style:paragraph-properties fo:break-before="page"/>
      </style:style>
      <style:style style:name="PASIDE" style:display-name="Panels: Aside" style:parent-style-name="PBASE" style:family="paragraph">
        <style:paragraph-properties fo:margin-left="0.5in" fo:margin-right="0.5in" fo:text-indent="0in" style:auto-text-indent="false"/>
      </style:style>
      <style:style style:name="PDIALOG" style:display-name="Panels: Dialog" style:family="paragraph" style:parent-style-name="PBASE">
        <style:paragraph-properties fo:text-align="center" style:justify-single-word="false"/>
      </style:style>
    </office:styles>'));

		doc.append(parseXml('<office:font-face-decls>
      <style:font-face style:name="Arial" svg:font-family="Arial" style:font-family-generic="swiss" style:font-pitch="variable"/>
    </office:font-face-decls>'));
		doc.append(parseXml('<office:master-styles>
      <style:master-page style:name="Standard" style:page-layout-name="pm1"/>
    </office:master-styles>'));
		doc.append(Xml.createElement('office:meta'));
		doc.append(Xml.createElement('office:scripts'));
		doc.append(Xml.createElement('office:settings'));

		var body = Xml.createElement('office:body');
		doc.append(body);

		var textBody = Xml.createElement('office:text');
		textBody.set('text:use-soft-page-breaks', 'true');
		textBody.append(parseXml('<text:sequence-decls>
      <text:sequence-decl text:display-outline-level="0" text:name="Illustration"/>
      <text:sequence-decl text:display-outline-level="0" text:name="Table"/>
      <text:sequence-decl text:display-outline-level="0" text:name="Text"/>
      <text:sequence-decl text:display-outline-level="0" text:name="Drawing"/>
      <text:sequence-decl text:display-outline-level="0" text:name="Figure"/>
    </text:sequence-decls>'));

		for (node in nodes) textBody.append(generateNode(node, context));

		body.append(textBody);

		return doc;
	}

	function generateParagraph(nodes:Array<Node>, context) {
		return p([], nodes.map(n -> generateNode(n, context)));
	}

	function generateText(content:TextType):Xml {
		return switch content {
			case Normal(value):
				text(value);
			case Bold(value):
				span(['text:style-name' => 'PB'], [text(value)]);
			case Italic(value):
				span(['text:style-name' => 'PI'], [text(value)]);
			case Link(label, url):
				text('(link not implemented yet)');
		}
	}

	function generatePage(nodes:Array<Node>, context:OpenDocumentGeneratorContext, isTwoPager = false) {
		context.currentPage++;
		context.currentPanel = 0;

		var children = nodes.map(n -> generateNode(n, context)); // <- This must go here to ensure context.currentPanel is right
		var titleText = switch isTwoPager {
			case true:
				var title = 'Pages ${context.currentPage} to ${context.currentPage + 1} (Spread)';
				context.currentPage += 1;
				title;
			case false:
				'Page ${context.currentPage}';
		}

		if (config.includePanelCount == true) {
			titleText += ' - ${context.currentPanel} Panels';
		}

		return fragment([
			h(['text:style-name' => 'PTITLE'], [text(titleText)]),
			fragment(children),
			p(['text:style-name' => 'PPAGEBREAK'], [node('text:line-break', [], [])])
		]);
	}

	function generatePanel(type:PanelType, children:Array<Node>, context:OpenDocumentGeneratorContext) {
		context.currentPanel++;

		var number = Std.string(switch type {
			case Auto: context.currentPanel;
			case UserDefined(number): number;
		});

		return fragment([
			h(['text:style-name' => 'PPANEL'], [text('PANEL ${number}')]),
			fragment(children.map(child -> generateNode(child, context)))
		]);
	}

	function generateDialog(name:String, modifiers:Array<Node>, content:Array<Node>, context:OpenDocumentGeneratorContext) {
		return fragment([
			p(['text:style-name' => 'PDIALOG'], [text(name)]),
			fragment(content.map(n -> generateNode(n, context)).map(el -> {
				el.set('text:style-name', 'PDIALOG');
				el;
			}))
		]);
	}

	function generateAside(nodes:Array<Node>, context:OpenDocumentGeneratorContext) {
		return fragment(nodes.map(n -> switch n.node {
			case Paragraph(nodes):
				p(['text:style-name' => 'PASIDE'], nodes.map(n -> generateNode(n, context)));
			default:
				generateNode(n, context);
		}));
	}

	function node(tag:String, attrs:Map<String, String>, children:Array<Xml>):Xml {
		var node = Xml.createElement(tag);
		for (key => value in attrs) node.set(key, value);
		for (item in children) node.append(item);
		return node;
	}

	function span(attrs:Map<String, String>, children:Array<Xml>) {
		return node('text:span', attrs, children);
	}

	function h(attrs:Map<String, String>, children:Array<Xml>) {
		if (!attrs.exists('text:style-name')) {
			attrs.set('text:style-name', 'PBASE');
		}
		return node('text:h', attrs, children);
	}

	function p(attrs:Map<String, String>, children:Array<Xml>) {
		if (!attrs.exists('text:style-name')) {
			attrs.set('text:style-name', 'PBASE');
		}
		return node('text:p', attrs, children);
	}

	function fragment(content:Array<Xml>) {
		var node = Xml.createDocument();
		for (item in content) node.append(item);
		return node;
	}

	function text(content:String) {
		return Xml.createPCData(content);
	}

	function parseXml(text:String) {
		return Xml.parse(text.split('\n').map(line -> line.trim()).join(' '));
	}
}

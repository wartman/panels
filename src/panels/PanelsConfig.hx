package panels;

@:forward
abstract PanelsConfig(PanelsConfigObject) from PanelsConfigObject to PanelsConfigObject {
	public function new(config) {
		this = config;
	}
}

typedef PanelsConfigObject = {
	public var compiler:CompilerConfig;
	public var validator:ValidatorConfig;
}

typedef CompilerConfig = {
	public var ?startPage:Int;
	public var ?includeSections:Bool;
	public var ?includeFrontmatter:Bool;
	public var ?includePanelCount:Bool;
	// @todo: Add more
}

typedef ValidatorConfig = {
	public var ?requireTitle:Bool;
	public var ?requireAuthor:Bool;
	// public var ?requireProperties:Array<String>;
	public var ?maxPanelsPerPage:Int;
	public var ?maxWordsPerDialog:Int;
	public var ?checkPanelOrder:Bool;
}

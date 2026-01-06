package panels;

import panels.Validator;

using Lambda;

class Compiler {
	final source:Source;
	final reporter:Reporter;
	final config:PanelsConfig;

	public function new(source, reporter, config) {
		this.source = source;
		this.reporter = reporter;
		this.config = config;
	}

	public function compile():Promise<Node> {
		try {
			var parser = new Parser(source);
			var node = parser.parse();
			var validator = new Validator(node, config.validator);
			var errors = validator.validate();

			if (errors.length > 0) {
				for (e in errors) reporter.report(e, source);
				// @todo: Allow compilation to continue if we only have Warnings?
				return new Error(InternalError, 'Failed to compile');
			}

			return node;
		} catch (e:ParserException) {
			reporter.report(e.toReporterMessage(), source);
			return new Error(InternalError, 'Failed to compile');
		}
	}
}

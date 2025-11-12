/**
 * Transform Terraform plan output to diff format for syntax highlighting
 *
 * This transformation converts Terraform plan output into a valid diff format
 * that highlight.js can properly highlight with the 'diff' language mode.
 *
 * Transformations applied:
 * 1. Move diff symbols (+, -, ~) from after spaces to before spaces
 *    Example: "  + resource" becomes "+   resource"
 * 2. Convert ~ to ! (Terraform "change" symbol to diff "modified" symbol)
 *
 * @param planText - Raw Terraform plan output text
 * @returns Transformed text in diff format suitable for highlight.js
 */
export function transformPlanToDiff(planText: string): string {
	return planText
		.split('\n')
		.map((line) => {
			// Move diff symbols (+, -, ~) from after spaces to before spaces
			// Pattern: "  + foo" becomes "+   foo"
			const match = line.match(/^( +)([+~-])/);
			if (match) {
				const spaces = match[1];
				const symbol = match[2];
				const rest = line.slice(spaces.length + 1);
				return symbol + spaces + rest;
			}
			return line;
		})
		.map((line) => {
			// Convert ~ to ! (Terraform "change" symbol to diff "modified" symbol)
			if (line.length > 0 && line[0] === '~') {
				return '!' + line.slice(1);
			}
			return line;
		})
		.join('\n');
}

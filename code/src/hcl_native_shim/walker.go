// walker.go translates hashicorp/hcl/v2's hclsyntax AST into the
// ppx_deriving_yojson encoding of Hcl_parser_value.t.
//
// Fidelity notes, with fixups that need the raw source bytes:
//
//   - Block_label: hclsyntax flattens quoted-vs-bareword labels into plain
//     strings in Block.Labels. We recover the distinction by peeking at the
//     first byte of LabelRanges[i]: `"` -> Lit, otherwise Id. (The HCL2
//     grammar only admits those two shapes for labels.)
//
//   - Heredoc vs Heredoc': hclsyntax folds heredoc bodies into regular
//     TemplateExpr nodes. To recover Hcl_parser_value.Expr.Heredoc /
//     Heredoc', we peek at the bytes at TemplateExpr.SrcRange.Start and
//     check for "<<-" (strip-indent, Heredoc') vs "<<" (Heredoc).
//
//   - Bare strings: TemplateExpr with a single LiteralValueExpr part and no
//     interpolation could be `Expr.String` or `Expr.Template [Literal ...]`.
//     We emit String only when the source span is a double-quoted string
//     with no interpolation; otherwise Template (matches the Menhir
//     parser's choice).

package main

import (
	"fmt"
	"math/big"
	"strings"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
)

// encodeBody converts an *hclsyntax.Body into the top-level
// Hcl_parser_value.t list (a json array). The list preserves source order:
// attributes and blocks are interleaved as they appear in the source. We
// achieve this by sorting all children by their source-range start offset.
func encodeBody(src []byte, body *hclsyntax.Body) []jsonValue {
	type child struct {
		start int
		v     jsonValue
	}
	children := make([]child, 0, len(body.Attributes)+len(body.Blocks))
	for _, a := range body.Attributes {
		children = append(children, child{start: a.SrcRange.Start.Byte, v: encodeAttribute(src, a)})
	}
	for _, b := range body.Blocks {
		children = append(children, child{start: b.TypeRange.Start.Byte, v: encodeBlock(src, b)})
	}
	// Insertion sort — block/attribute counts are tiny in practice.
	for i := 1; i < len(children); i++ {
		for j := i; j > 0 && children[j-1].start > children[j].start; j-- {
			children[j-1], children[j] = children[j], children[j-1]
		}
	}
	out := make([]jsonValue, len(children))
	for i, c := range children {
		out[i] = c.v
	}
	return out
}

// encodeAttribute -> ["Attribute", name, expr]
func encodeAttribute(src []byte, a *hclsyntax.Attribute) jsonValue {
	return tag2("Attribute", a.Name, encodeExpr(src, a.Expr))
}

// encodeBlock -> ["Block", {"type_": ..., "labels": [...], "body": [...]}]
func encodeBlock(src []byte, b *hclsyntax.Block) jsonValue {
	labels := make([]jsonValue, len(b.Labels))
	for i, label := range b.Labels {
		labels[i] = encodeLabel(src, b.LabelRanges[i], label)
	}
	rec := map[string]jsonValue{
		"type_":  b.Type,
		"labels": labels,
		"body":   encodeBody(src, b.Body),
	}
	return tagRec("Block", rec)
}

// encodeLabel -> ["Id", s] or ["Lit", s] based on the source form.
func encodeLabel(src []byte, rng hcl.Range, label string) jsonValue {
	if rng.Start.Byte < len(src) && src[rng.Start.Byte] == '"' {
		return tag1("Lit", label)
	}
	return tag1("Id", label)
}

// encodeExpr dispatches on the concrete hclsyntax expression type.
func encodeExpr(src []byte, expr hclsyntax.Expression) jsonValue {
	switch e := expr.(type) {
	case *hclsyntax.LiteralValueExpr:
		return encodeLiteral(e.Val)
	case *hclsyntax.ScopeTraversalExpr:
		return encodeTraversal(src, e.Traversal)
	case *hclsyntax.RelativeTraversalExpr:
		return encodeRelativeTraversal(src, e)
	case *hclsyntax.TemplateExpr:
		return encodeTemplate(src, e)
	case *hclsyntax.TemplateWrapExpr:
		// A bare interpolation without surrounding text: treat as a Template
		// with one Interpolation part. Recover [~] strip markers from the
		// source bytes around the wrapped expression.
		sb, sa := templateStripMarkers(src, e.Wrapped.Range())
		return tag1("Template", []jsonValue{encodeInterpolation(src, e.Wrapped, sb, sa)})
	case *hclsyntax.FunctionCallExpr:
		return encodeFunctionCall(src, e)
	case *hclsyntax.BinaryOpExpr:
		return encodeBinaryOp(src, e)
	case *hclsyntax.UnaryOpExpr:
		return encodeUnaryOp(src, e)
	case *hclsyntax.ConditionalExpr:
		return tagRec("Cond", map[string]jsonValue{
			"if_":   encodeExpr(src, e.Condition),
			"then_": encodeExpr(src, e.TrueResult),
			"else_": encodeExpr(src, e.FalseResult),
		})
	case *hclsyntax.ForExpr:
		return encodeForExpr(src, e)
	case *hclsyntax.ObjectConsExpr:
		return encodeObjectCons(src, e)
	case *hclsyntax.ObjectConsKeyExpr:
		return encodeExpr(src, e.Wrapped)
	case *hclsyntax.TupleConsExpr:
		items := make([]jsonValue, len(e.Exprs))
		for i, x := range e.Exprs {
			items[i] = encodeExpr(src, x)
		}
		return tag1("Tuple", items)
	case *hclsyntax.IndexExpr:
		return tagTuple2("Idx", encodeExpr(src, e.Collection), encodeExpr(src, e.Key))
	case *hclsyntax.SplatExpr:
		return encodeSplat(src, e)
	case *hclsyntax.AnonSymbolExpr:
		// Anonymous symbol inside a splat's Each expression — at the outer
		// level the splat printer replaces it with `Splat`, but if we hit it
		// standalone we emit the same sentinel.
		return tag0("Splat")
	case *hclsyntax.ParenthesesExpr:
		return encodeExpr(src, e.Expression)
	case *hclsyntax.ExprSyntaxError:
		return tag1("Id", "__HCL_SYNTAX_ERROR__")
	default:
		return tag1("Id", fmt.Sprintf("__UNSUPPORTED_EXPR_%T__", e))
	}
}

// encodeLiteral turns a cty.Value literal into the matching
// Hcl_parser_value.Expr constructor.
func encodeLiteral(v cty.Value) jsonValue {
	if v.IsNull() {
		return tag0("Null")
	}
	ty := v.Type()
	switch {
	case ty == cty.String:
		return tag1("String", v.AsString())
	case ty == cty.Bool:
		return tag1("Bool", v.True())
	case ty == cty.Number:
		bf := v.AsBigFloat()
		if bf.IsInt() {
			if i, acc := bf.Int64(); acc == big.Exact {
				return tag1("Int", i)
			}
		}
		f, _ := bf.Float64()
		return tag1("Float", f)
	default:
		// Fall back to a tagged string so the OCaml decoder can at least
		// parse the payload. Non-primitive literals (e.g. lists, objects)
		// don't normally appear as raw hclsyntax.LiteralValueExpr — the
		// parser produces ObjectConsExpr / TupleConsExpr instead.
		return tag1("String", fmt.Sprintf("__NON_PRIMITIVE_LITERAL__%s__", ty.FriendlyName()))
	}
}

// encodeTraversal turns a hcl.Traversal (chain of name/attr/index steps)
// into a nested Hcl_parser_value.Expr: root is `Id`, subsequent steps are
// `Attr (prev, ...)` or `Idx (prev, ...)`.
func encodeTraversal(src []byte, tr hcl.Traversal) jsonValue {
	if len(tr) == 0 {
		return tag1("Id", "")
	}
	var cur jsonValue
	switch s := tr[0].(type) {
	case hcl.TraverseRoot:
		cur = tag1("Id", s.Name)
	case hcl.TraverseAttr:
		cur = tag1("Id", s.Name)
	case hcl.TraverseIndex:
		cur = tag1("Id", "")
		cur = applyTraversalStep(src, cur, s)
	default:
		cur = tag1("Id", fmt.Sprintf("__TRAVERSAL_HEAD_%T__", s))
	}
	for _, step := range tr[1:] {
		cur = applyTraversalStep(src, cur, step)
	}
	return cur
}

// encodeRelativeTraversal applies traversal steps to a source expression.
func encodeRelativeTraversal(src []byte, e *hclsyntax.RelativeTraversalExpr) jsonValue {
	cur := encodeExpr(src, e.Source)
	for _, step := range e.Traversal {
		cur = applyTraversalStep(src, cur, step)
	}
	return cur
}

// stepStartsWithDot returns true if the source bytes at the beginning of
// [step]'s SourceRange are a `.` (dot-prefixed syntax such as `.0` or
// `.*`). This lets us distinguish the syntactic form without relying on
// the key value alone.
func stepStartsWithDot(src []byte, step hcl.Traverser) bool {
	rng := step.SourceRange()
	return rng.Start.Byte < len(src) && src[rng.Start.Byte] == '.'
}

// applyTraversalStep mirrors the Menhir parser's encoding, which preserves
// the SYNTACTIC form of each traversal step:
//
//   - `.name`  -> Attr(base, A_string name)
//   - `.N`     -> Attr(base, A_int N)     // dot-integer tuple index
//   - `.*`     -> Attr(base, A_splat)     // attribute splat
//   - `[n]`    -> Idx(base, <literal>)    // any literal key (Int/String/...)
//   - `[*]`    -> Idx(base, Splat)        // full splat
//
// The Menhir parser does NOT collapse `a["b"]` into `Attr(_, A_string "b")`;
// it preserves the bracket form as Idx. Conversely, `a.0` stays in the
// Attr/A_int form rather than becoming Idx, and `a.*` stays in Attr/A_splat
// rather than the Idx/Splat that `a[*]` produces.
func applyTraversalStep(src []byte, base jsonValue, step hcl.Traverser) jsonValue {
	switch s := step.(type) {
	case hcl.TraverseAttr:
		return tagTuple2("Attr", base, tag1("A_string", s.Name))
	case hcl.TraverseIndex:
		if stepStartsWithDot(src, s) {
			if s.Key.Type() == cty.Number {
				bf := s.Key.AsBigFloat()
				if bf.IsInt() {
					if i, acc := bf.Int64(); acc == big.Exact {
						return tagTuple2("Attr", base, tag1("A_int", i))
					}
				}
			}
			// Dot-prefixed non-integer index — fall through to the Idx form;
			// hclsyntax won't produce this from source, but it's safe.
		}
		return tagTuple2("Idx", base, encodeLiteral(s.Key))
	case hcl.TraverseSplat:
		if stepStartsWithDot(src, s) {
			return tagTuple2("Attr", base, tag0("A_splat"))
		}
		return tagTuple2("Idx", base, tag0("Splat"))
	default:
		return base
	}
}

// encodeTemplate handles string-like expressions. hcl/v2 represents both
// quoted strings and heredocs as TemplateExpr; we disambiguate heredocs via
// the source bytes at SrcRange.Start.
//
// Menhir convention: heredocs are stored as opaque (marker, raw body) pairs —
// `<<EOF` under the `Heredoc` constructor and `<<-EOF` under `Heredoc'`. In both
// cases the body is the exact bytes between the opening marker's newline and the
// closing marker, verbatim. We deliberately do NOT apply the `<<-`
// common-leading-whitespace strip here: hclsyntax flushes the flat token stream
// before the expression tree is built (so newlines inside `${...}`/`%{...}`
// don't participate), which the OCaml side reproduces in
// Hcl_ast_template.flush_heredoc_body on the `Heredoc'` node. Reading directly
// from source keeps hclsyntax's template-structure interpretation from leaking
// through.
func encodeTemplate(src []byte, e *hclsyntax.TemplateExpr) jsonValue {
	if marker, body, flush, ok := detectHeredoc(src, e.SrcRange); ok {
		if flush {
			return tagTuple2("Heredoc'", marker, body)
		}
		return tagTuple2("Heredoc", marker, body)
	}
	// Special case: a template with a single literal part renders as a
	// simple String.
	if len(e.Parts) == 1 {
		if lit, isLit := e.Parts[0].(*hclsyntax.LiteralValueExpr); isLit {
			if lit.Val.Type() == cty.String {
				return tag1("String", lit.Val.AsString())
			}
		}
	}
	if len(e.Parts) == 0 {
		return tag1("String", "")
	}
	parts := make([]jsonValue, 0, len(e.Parts))
	for _, p := range e.Parts {
		parts = append(parts, encodeTemplatePart(src, p))
	}
	return tag1("Template", parts)
}

// detectHeredoc peeks at the source bytes of a TemplateExpr's range to
// determine whether it came from a heredoc literal, and if so returns the
// marker, the raw body bytes, and whether it is a `<<-` (flush) heredoc. Both
// `<<` and `<<-` open a heredoc; the `<<-` common-leading-whitespace strip is
// applied later, on the OCaml side (see encodeTemplate).
func detectHeredoc(src []byte, rng hcl.Range) (marker, body string, flush, ok bool) {
	lo := rng.Start.Byte
	hi := rng.End.Byte
	if lo < 0 || hi > len(src) || hi <= lo+2 {
		return "", "", false, false
	}
	window := string(src[lo:hi])
	var prefixLen int
	switch {
	case strings.HasPrefix(window, "<<-"):
		prefixLen = 3
	case strings.HasPrefix(window, "<<"):
		prefixLen = 2
	default:
		return "", "", false, false
	}
	rest := window[prefixLen:]
	nl := strings.IndexByte(rest, '\n')
	if nl < 0 {
		return "", "", false, false
	}
	marker = strings.TrimSpace(rest[:nl])
	// Body is the literal source bytes from the newline that follows the
	// opening marker up to and including the newline that terminates the
	// last content line. For indented closing markers (`<<-EOT` with the
	// closing `  EOT`), we walk back through the marker's leading
	// whitespace so the indent isn't included, but the preceding \n stays.
	body = rest[nl:]
	if idx := strings.LastIndex(body, marker); idx >= 0 {
		trimEnd := idx
		for trimEnd > 0 && (body[trimEnd-1] == ' ' || body[trimEnd-1] == '\t') {
			trimEnd--
		}
		body = body[:trimEnd]
	}
	return marker, body, prefixLen == 3, true
}

// encodeTemplatePart renders a single element of a TemplateExpr's Parts.
// Literal text becomes Literal; otherwise we discriminate between the
// three possible shapes of non-literal parts produced by hclsyntax:
//
//   - `%{ for ... }body%{ endfor }`  -> TemplateJoinExpr    -> For_directive
//   - `%{ if ... }then%{ else }else%{ endif }` -> ConditionalExpr
//     whose Source range begins with `%{` -> If_directive
//   - plain `${...}` interpolations (including `?:` ternaries) -> Interpolation
//
// The discriminator for the if-directive case is a source-byte check: a
// ConditionalExpr produced from `%{if}` spans a Range that starts with
// the literal `%{` bytes, whereas a `${a ? b : c}` ternary's
// ConditionalExpr starts at the `a` token. This is the cheapest
// reliable test hclsyntax gives us without walking its lexer tokens.
func encodeTemplatePart(src []byte, p hclsyntax.Expression) jsonValue {
	stripBefore, stripAfter := templateStripMarkers(src, p.Range())
	switch part := p.(type) {
	case *hclsyntax.LiteralValueExpr:
		if part.Val.Type() == cty.String {
			return tag1("Literal", part.Val.AsString())
		}
		return tag1("Literal", "")
	case *hclsyntax.TemplateJoinExpr:
		return encodeForDirective(src, part, stripBefore, stripAfter)
	case *hclsyntax.ConditionalExpr:
		if rangeStartsWithPercentOpen(src, part.Range()) {
			return encodeIfDirective(src, part, stripBefore, stripAfter)
		}
		return encodeInterpolation(src, part, stripBefore, stripAfter)
	default:
		return encodeInterpolation(src, part, stripBefore, stripAfter)
	}
}

// rangeStartsWithPercentOpen reports whether the source bytes at the
// start of [rng] are `%{`, i.e. the opening of a template directive.
func rangeStartsWithPercentOpen(src []byte, rng hcl.Range) bool {
	lo := rng.Start.Byte
	return lo >= 0 && lo+1 < len(src) && src[lo] == '%' && src[lo+1] == '{'
}

// templateStripMarkers inspects the source bytes around a non-literal
// template part's range and recovers the strip markers (`~`) at the two
// ends of the opening delimiter.
//
// Two cases, because hclsyntax reports the part's range differently
// depending on which kind of part it is:
//
//  1. Directives / template-wrapping expressions (ConditionalExpr from
//     `%{if}`, TemplateJoinExpr from `%{for}`): the range INCLUDES the
//     `%{…}` delimiters, so `~` sits inside the range — right after
//     `%{` for strip_before, right before the first `}` for strip_after.
//
//  2. Plain `${…}` interpolations: the range is just the inner
//     expression (e.g. ScopeTraversalExpr for `var.name`). The `~`
//     markers live OUTSIDE the range, possibly with whitespace between
//     them and the inner expression. We scan backward from rng.Start-1
//     and forward from rng.End, skipping space/tab, and check whether
//     the first non-whitespace byte we hit is `~`.
func templateStripMarkers(src []byte, rng hcl.Range) (bool, bool) {
	lo := rng.Start.Byte
	hi := rng.End.Byte
	if lo < 0 || hi > len(src) || lo >= hi {
		return false, false
	}
	// Case 1: range begins with `${` or `%{`.
	if lo+1 < len(src) && (src[lo] == '$' || src[lo] == '%') && src[lo+1] == '{' {
		stripBefore := lo+2 < hi && src[lo+2] == '~'
		stripAfter := false
		for i := lo + 2; i < hi; i++ {
			if src[i] == '}' {
				stripAfter = i > 0 && src[i-1] == '~'
				break
			}
		}
		return stripBefore, stripAfter
	}
	// Case 2: scan outward from the range boundaries.
	stripBefore := firstNonWhitespaceIs(src, lo-1, -1, '~')
	stripAfter := firstNonWhitespaceIs(src, hi, +1, '~')
	return stripBefore, stripAfter
}

// firstNonWhitespaceIs walks [src] from index [start] in direction
// [step] (either -1 or +1), skipping space / tab bytes, and returns
// true iff the first non-whitespace byte encountered equals [want].
// Returns false if the walk runs off the ends of [src].
func firstNonWhitespaceIs(src []byte, start, step int, want byte) bool {
	for i := start; i >= 0 && i < len(src); i += step {
		b := src[i]
		if b == ' ' || b == '\t' {
			continue
		}
		return b == want
	}
	return false
}

func encodeInterpolation(src []byte, inner hclsyntax.Expression, stripBefore, stripAfter bool) jsonValue {
	return tagRec("Interpolation", map[string]jsonValue{
		"expr":         encodeExpr(src, inner),
		"strip_before": stripBefore,
		"strip_after":  stripAfter,
	})
}

// encodeIfDirective emits If_directive from a ConditionalExpr produced
// by the `%{if ... }then%{else}else%{endif}` form. Both branches are
// themselves TemplateExpr-shaped, and we decompose them into the
// [then_] / [else_] template-part lists Hcl_parser_value expects.
//
// hclsyntax's parseIf always injects a LiteralValueExpr("") into an
// otherwise-empty then or else branch (so TemplateExpr.Parts is never
// zero-length). That injection is an internal invariant of the Go
// parser, not something that should leak into our cross-parser AST, so
// when the branch evaluates to an empty string we emit [] for then and
// [] / null (None) for else to match Menhir's natural representation.
func encodeIfDirective(src []byte, e *hclsyntax.ConditionalExpr, stripBefore, stripAfter bool) jsonValue {
	cond := encodeExpr(src, e.Condition)
	var thenParts jsonValue
	if isEmptyTemplate(e.TrueResult) {
		thenParts = []jsonValue{}
	} else {
		thenParts = extractTemplateParts(src, e.TrueResult)
	}
	var elseParts jsonValue
	if isEmptyTemplate(e.FalseResult) {
		elseParts = nil
	} else {
		elseParts = extractTemplateParts(src, e.FalseResult)
	}
	rec := map[string]jsonValue{
		"cond":         cond,
		"then_":        thenParts,
		"else_":        elseParts,
		"strip_before": stripBefore,
		"strip_after":  stripAfter,
	}
	return tagRec("If_directive", rec)
}

// encodeForDirective emits For_directive from a TemplateJoinExpr
// produced by `%{for ... in ... }body%{endfor}`. The join wraps a
// ForExpr that iterates over the collection; the ForExpr's ValExpr is
// the per-iteration template whose Parts form the directive body.
//
// Like encodeIfDirective, we collapse an empty body (hclsyntax injects
// LiteralValueExpr("") when the for body is empty) to [] rather than
// [Literal ""].
func encodeForDirective(src []byte, e *hclsyntax.TemplateJoinExpr, stripBefore, stripAfter bool) jsonValue {
	forExpr, ok := e.Tuple.(*hclsyntax.ForExpr)
	if !ok {
		return encodeInterpolation(src, e, stripBefore, stripAfter)
	}
	var body jsonValue
	if isEmptyTemplate(forExpr.ValExpr) {
		body = []jsonValue{}
	} else {
		body = extractTemplateParts(src, forExpr.ValExpr)
	}
	rec := map[string]jsonValue{
		"vars":         encodeForDirectiveVars(forExpr.KeyVar, forExpr.ValVar),
		"input":        encodeExpr(src, forExpr.CollExpr),
		"body":         body,
		"strip_before": stripBefore,
		"strip_after":  stripAfter,
	}
	return tagRec("For_directive", rec)
}

// encodeForDirectiveVars mirrors the [Hcl_parser_value.Template_part.For_directive.vars]
// shape: `string * string option`, documented as `(value, optional key)`.
// For `%{for v in xs}` hclsyntax sets KeyVar="" and ValVar="v" — we emit
// [(v, None)]. For `%{for k, v in xs}` it sets KeyVar="k" and ValVar="v" —
// we emit [(v, Some k)].
func encodeForDirectiveVars(keyVar, valVar string) jsonValue {
	var key jsonValue
	if keyVar == "" {
		key = nil
	} else {
		key = keyVar
	}
	return []jsonValue{valVar, key}
}

// extractTemplateParts turns an expression that represents a template
// body into the list of template parts Hcl_parser_value expects.
func extractTemplateParts(src []byte, e hclsyntax.Expression) []jsonValue {
	switch tpl := e.(type) {
	case *hclsyntax.TemplateExpr:
		parts := make([]jsonValue, 0, len(tpl.Parts))
		for _, p := range tpl.Parts {
			parts = append(parts, encodeTemplatePart(src, p))
		}
		return parts
	case *hclsyntax.TemplateWrapExpr:
		sb, sa := templateStripMarkers(src, tpl.Range())
		return []jsonValue{encodeInterpolation(src, tpl.Wrapped, sb, sa)}
	case *hclsyntax.LiteralValueExpr:
		if tpl.Val.Type() == cty.String {
			return []jsonValue{tag1("Literal", tpl.Val.AsString())}
		}
		return []jsonValue{tag1("Literal", "")}
	default:
		return []jsonValue{encodeInterpolation(src, e, false, false)}
	}
}

// isEmptyTemplate returns true if the given expression is a template
// (or a plain string literal) that produces an empty string. hclsyntax
// represents the implicit [else] branch of an `%{if}` without an
// explicit else as a TemplateExpr wrapping a single empty-string
// LiteralValueExpr — if we recognize that shape we can emit None for
// [else_] instead of [Some [Literal ""]].
func isEmptyTemplate(e hclsyntax.Expression) bool {
	switch tpl := e.(type) {
	case *hclsyntax.TemplateExpr:
		for _, p := range tpl.Parts {
			if !isEmptyTemplate(p) {
				return false
			}
		}
		return true
	case *hclsyntax.LiteralValueExpr:
		return tpl.Val.Type() == cty.String && tpl.Val.AsString() == ""
	default:
		return false
	}
}

func encodeFunctionCall(src []byte, e *hclsyntax.FunctionCallExpr) jsonValue {
	args := make([]jsonValue, len(e.Args))
	for i, a := range e.Args {
		args[i] = encodeExpr(src, a)
	}
	if e.ExpandFinal && len(args) > 0 {
		last := args[len(args)-1]
		args[len(args)-1] = tag1("Ellipsis", last)
	}
	return tagTuple2("Fun_call", e.Name, args)
}

// binaryOpCtor returns the Hcl_parser_value.Expr constructor name for an
// hclsyntax.Operation. The names match Menhir's parser's op constructors.
func binaryOpCtor(op *hclsyntax.Operation) string {
	switch op {
	case hclsyntax.OpAdd:
		return "Add"
	case hclsyntax.OpSubtract:
		return "Subtract"
	case hclsyntax.OpMultiply:
		return "Mult"
	case hclsyntax.OpDivide:
		return "Div"
	case hclsyntax.OpModulo:
		return "Mod"
	case hclsyntax.OpLogicalAnd:
		return "Log_and"
	case hclsyntax.OpLogicalOr:
		return "Log_or"
	case hclsyntax.OpEqual:
		return "Equal"
	case hclsyntax.OpNotEqual:
		return "Not_equal"
	case hclsyntax.OpGreaterThan:
		return "Gt"
	case hclsyntax.OpGreaterThanOrEqual:
		return "Gte"
	case hclsyntax.OpLessThan:
		return "Lt"
	case hclsyntax.OpLessThanOrEqual:
		return "Lte"
	default:
		return ""
	}
}

func encodeBinaryOp(src []byte, e *hclsyntax.BinaryOpExpr) jsonValue {
	name := binaryOpCtor(e.Op)
	if name == "" {
		return tag1("Id", "__UNKNOWN_BINOP__")
	}
	return tagTuple2(name, encodeExpr(src, e.LHS), encodeExpr(src, e.RHS))
}

func encodeUnaryOp(src []byte, e *hclsyntax.UnaryOpExpr) jsonValue {
	switch e.Op {
	case hclsyntax.OpLogicalNot:
		return tag1("Not", encodeExpr(src, e.Val))
	case hclsyntax.OpNegate:
		return tag1("Minus", encodeExpr(src, e.Val))
	default:
		return encodeExpr(src, e.Val)
	}
}

func encodeForExpr(src []byte, e *hclsyntax.ForExpr) jsonValue {
	identifiers := encodeForIdentifiers(e.KeyVar, e.ValVar)
	var cond jsonValue
	if e.CondExpr != nil {
		cond = encodeExpr(src, e.CondExpr)
	}
	// `e.Group` is set when the value expression ends with `...` — the
	// Menhir parser wraps the value_output in an `Ellipsis` for this case.
	wrapGroup := func(v jsonValue) jsonValue {
		if e.Group {
			return tag1("Ellipsis", v)
		}
		return v
	}
	if e.KeyExpr != nil {
		// Object-producing for: { k_expr => v_expr... for ... }
		return tagRec("For_object", map[string]jsonValue{
			"identifiers":  identifiers,
			"input":        encodeExpr(src, e.CollExpr),
			"key_output":   encodeExpr(src, e.KeyExpr),
			"value_output": wrapGroup(encodeExpr(src, e.ValExpr)),
			"cond":         cond,
		})
	}
	return tagRec("For_tuple", map[string]jsonValue{
		"identifiers": identifiers,
		"input":       encodeExpr(src, e.CollExpr),
		"output":      wrapGroup(encodeExpr(src, e.ValExpr)),
		"cond":        cond,
	})
}

// encodeForIdentifiers mirrors the `string * string list` encoding used by
// Hcl_parser_value.Expr.For_*.identifiers. When only the value variable is
// declared, identifiers is (valName, []); when a key variable is also
// present, identifiers is (keyName, [valName]).
func encodeForIdentifiers(keyVar, valVar string) jsonValue {
	if keyVar == "" {
		return []jsonValue{valVar, []jsonValue{}}
	}
	return []jsonValue{keyVar, []jsonValue{valVar}}
}

func encodeObjectCons(src []byte, e *hclsyntax.ObjectConsExpr) jsonValue {
	pairs := make([]jsonValue, 0, len(e.Items))
	for _, item := range e.Items {
		pairs = append(pairs, []jsonValue{
			encodeObjectKey(src, item.KeyExpr),
			encodeExpr(src, item.ValueExpr),
		})
	}
	return tag1("Object", pairs)
}

// encodeObjectKey emits the [Obj_key.t] sum the OCaml side expects. Each
// constructor preserves a distinct surface form:
//
//   - `k = v`          -> [Bare "k"]            (bareword identifier)
//   - `0 = v`          -> [Bare "0"]            (integer literal, raw text)
//   - `80.0 = v`       -> [Bare "80.0"]         (float literal, raw text)
//   - `true = v`       -> [Bare "true"]         (keyword literal as key)
//   - `"lit" = v`      -> [Quoted "lit"]        (quoted string, no template)
//   - `"${x}" = v`     -> [Template parts]      (quoted string with template)
//   - `(expr) = v`     -> [Computed encoded(expr)]  (ForceNonLiteral=true)
//   - `a.b = v`        -> [Expr [Attr ...]]     (compound expr, no parens)
//   - `-1 = v`         -> [Expr [Minus [Int 1]]]
//   - `f(x) = v`       -> [Expr [Fun_call ...]]
//
// Per the HCL spec
// (https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md#collection-values),
// [Bare] / [Quoted] are literal-name keys, [Template] evaluates the
// template, and [Computed] forces evaluation of the wrapped expression.
// [Expr] is the lenient hclsyntax form that admits compound keys without
// the spec-required parens.
func encodeObjectKey(src []byte, key hclsyntax.Expression) jsonValue {
	wrap, ok := key.(*hclsyntax.ObjectConsKeyExpr)
	if !ok {
		// Defensive: ObjectConsExpr items always wrap their key, but if
		// we ever see a bare expression here, treat it as a non-paren
		// compound key.
		return tag1("Expr", encodeExpr(src, key))
	}
	if wrap.ForceNonLiteral {
		// Source had explicit parens around the key: [Computed expr].
		return tag1("Computed", encodeExpr(src, wrap.Wrapped))
	}
	rng := wrap.Range()
	lo, hi := rng.Start.Byte, rng.End.Byte
	raw := ""
	if lo >= 0 && hi <= len(src) && lo < hi {
		raw = string(src[lo:hi])
	}
	switch inner := wrap.Wrapped.(type) {
	case *hclsyntax.ScopeTraversalExpr:
		// Single-root traversal is the bareword identifier case
		// ([k = v], [in = v], [for = v]). Multi-step ([a.b]) is a
		// compound expression with no parens — [Expr].
		if len(inner.Traversal) == 1 {
			if root, ok := inner.Traversal[0].(hcl.TraverseRoot); ok {
				return tag1("Bare", root.Name)
			}
		}
		return tag1("Expr", encodeExpr(src, inner))
	case *hclsyntax.LiteralValueExpr:
		// Numeric, boolean, or null literal as unquoted key: stringify
		// the raw source so [0] -> "0", [80.0] -> "80.0", [true] -> "true".
		if raw != "" {
			return tag1("Bare", raw)
		}
		return tag1("Expr", encodeExpr(src, inner))
	case *hclsyntax.TemplateExpr:
		// Quoted-string key. A template with a single literal part is a
		// plain quoted string ([Quoted]); anything richer (multiple
		// parts, interpolations, directives) is a template expression
		// ([Template]). Heredocs are not legal as obj keys but we guard
		// defensively.
		if _, _, _, isHeredoc := detectHeredoc(src, inner.SrcRange); isHeredoc {
			return tag1("Expr", encodeExpr(src, inner))
		}
		if len(inner.Parts) == 0 {
			return tag1("Quoted", "")
		}
		if len(inner.Parts) == 1 {
			if lit, isLit := inner.Parts[0].(*hclsyntax.LiteralValueExpr); isLit {
				if lit.Val.Type() == cty.String {
					return tag1("Quoted", lit.Val.AsString())
				}
			}
		}
		parts := make([]jsonValue, 0, len(inner.Parts))
		for _, p := range inner.Parts {
			parts = append(parts, encodeTemplatePart(src, p))
		}
		return tag1("Template", parts)
	case *hclsyntax.TemplateWrapExpr:
		// [`"${foo}"`] — a quoted single bare interpolation. Always a
		// [Template] with one [Interpolation] part.
		sb, sa := templateStripMarkers(src, inner.Wrapped.Range())
		return tag1("Template", []jsonValue{encodeInterpolation(src, inner.Wrapped, sb, sa)})
	default:
		// FunctionCallExpr, UnaryOpExpr, IndexExpr, BinaryOpExpr,
		// ConditionalExpr, etc. — non-parenthesized compound key.
		return tag1("Expr", encodeExpr(src, inner))
	}
}

// encodeSplat turns an hclsyntax.SplatExpr into the matching Splat-step
// chain. The form of the splat marker in source decides the encoding:
//
//   - `a[*]` (full splat, MarkerRange starts with `[`) -> Idx(source, Splat)
//   - `a.*`  (attr splat, MarkerRange starts with `.`) -> Attr(source, A_splat)
//
// Any inner `Each` traversal is layered on top by substituting
// AnonSymbolExpr with the built base.
func encodeSplat(src []byte, e *hclsyntax.SplatExpr) jsonValue {
	base := splatBase(src, encodeExpr(src, e.Source), e.MarkerRange)
	return substAnonSymbol(src, base, e.Each, e.MarkerRange)
}

// splatBase encodes the splat marker itself, using MarkerRange to decide
// between the attribute-splat and full-splat forms.
func splatBase(src []byte, source jsonValue, marker hcl.Range) jsonValue {
	if marker.Start.Byte < len(src) && src[marker.Start.Byte] == '.' {
		return tagTuple2("Attr", source, tag0("A_splat"))
	}
	return tagTuple2("Idx", source, tag0("Splat"))
}

// substAnonSymbol walks an expression replacing AnonSymbolExpr with the
// given substitute. [outerMarker] is the MarkerRange of the enclosing
// splat.
//
// hclsyntax represents chained splats (e.g. `a[*].b[*].c`) as a SINGLE
// top-level SplatExpr whose Each is another SplatExpr whose Each may in
// turn be a RelativeTraversal. The Menhir parser flattens these into a
// linear chain of Attr/Idx steps. To match, we must (1) substitute
// AnonSymbolExpr with the running sub, and (2) on encountering a nested
// SplatExpr, emit its splat marker and THEN continue by substituting that
// splat's Each — don't stop at the nested splat.
func substAnonSymbol(src []byte, sub jsonValue, expr hclsyntax.Expression, outerMarker hcl.Range) jsonValue {
	switch e := expr.(type) {
	case *hclsyntax.AnonSymbolExpr:
		return sub
	case *hclsyntax.RelativeTraversalExpr:
		cur := substAnonSymbol(src, sub, e.Source, outerMarker)
		for _, step := range e.Traversal {
			cur = applyTraversalStep(src, cur, step)
		}
		return cur
	case *hclsyntax.SplatExpr:
		inner := substAnonSymbol(src, sub, e.Source, outerMarker)
		nestedBase := splatBase(src, inner, e.MarkerRange)
		return substAnonSymbol(src, nestedBase, e.Each, e.MarkerRange)
	default:
		return encodeExpr(src, expr)
	}
}

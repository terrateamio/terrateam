package main

import (
	"encoding/json"
	"fmt"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
)

// parseFileToJSON parses an HCL source blob (whole configuration file)
// and returns its encoded `Hcl_parser_value.t list` shape.
func parseFileToJSON(src []byte) (byte, []byte) {
	file, diags := hclsyntax.ParseConfig(src, "<stdin>", hcl.Pos{Line: 1, Column: 1})
	if diags.HasErrors() {
		return statusErr, []byte(fmt.Sprintf("hcl parse: %s", diags.Error()))
	}
	body, ok := file.Body.(*hclsyntax.Body)
	if !ok {
		return statusErr, []byte(fmt.Sprintf("hcl parse: unexpected body type %T", file.Body))
	}
	return marshal(encodeBody(src, body))
}

// parseExpressionToJSON parses a standalone expression (what appears
// inside `${...}` interpolations). Returns `Hcl_parser_value.Expr.t`.
func parseExpressionToJSON(src []byte) (byte, []byte) {
	expr, diags := hclsyntax.ParseExpression(src, "<stdin>", hcl.Pos{Line: 1, Column: 1})
	if diags.HasErrors() {
		return statusErr, []byte(fmt.Sprintf("hcl parse: %s", diags.Error()))
	}
	return marshal(encodeExpr(src, expr))
}

// parseTemplateToJSON parses template source (unquoted — the content
// between the quotes of a normal HCL string, not including the quotes
// themselves). Returns `Hcl_parser_value.Template_part.t list`.
//
// hclsyntax.ParseTemplate can return either a *hclsyntax.TemplateExpr
// (multi-part template) or a *hclsyntax.TemplateWrapExpr (single bare
// `${expr}` — an optimization that skips the template machinery). We
// normalize the latter into a one-element list with a single
// Interpolation part.
func parseTemplateToJSON(src []byte) (byte, []byte) {
	expr, diags := hclsyntax.ParseTemplate(src, "<stdin>", hcl.Pos{Line: 1, Column: 1})
	if diags.HasErrors() {
		return statusErr, []byte(fmt.Sprintf("hcl parse: %s", diags.Error()))
	}
	switch e := expr.(type) {
	case *hclsyntax.TemplateExpr:
		parts := make([]jsonValue, 0, len(e.Parts))
		for _, p := range e.Parts {
			parts = append(parts, encodeTemplatePart(src, p))
		}
		return marshal(parts)
	case *hclsyntax.TemplateWrapExpr:
		stripBefore, stripAfter := templateStripMarkers(src, e.Wrapped.Range())
		return marshal([]jsonValue{encodeInterpolation(src, e.Wrapped, stripBefore, stripAfter)})
	default:
		return statusErr, []byte(fmt.Sprintf("sg_hcl_shim: unexpected template type %T", expr))
	}
}

func marshal(v jsonValue) (byte, []byte) {
	buf, err := json.Marshal(v)
	if err != nil {
		return statusErr, []byte(fmt.Sprintf("json encode: %v", err))
	}
	return statusOk, buf
}

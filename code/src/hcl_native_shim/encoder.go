package main

// This file defines tiny helpers for emitting the ppx_deriving_yojson shape
// that `Hcl_parser_value.t` and its nested types serialize to:
//
//   - 0-arg constructor `C`                 -> ["C"]
//   - 1-arg constructor `C of t`            -> ["C", t_json]
//   - N-arg constructor `C of t1 * t2 ...`  -> ["C", t1_json, t2_json, ...]
//   - 1-arg tuple       `C of (t1 * t2)`    -> ["C", [t1_json, t2_json]]
//   - inline-record     `C of { f1; f2 }`   -> ["C", {"f1": v1, "f2": v2}]
//
// and some primitives:
//
//   - int     -> json number
//   - float   -> json number
//   - bool    -> json bool
//   - string  -> json string
//   - `t list`    -> json array
//   - `t option`  -> None -> null, Some x -> x_json  (ppx_deriving_yojson default)
//   - `t1 * t2`   -> [t1_json, t2_json]
//
// All encoders return `any` so the whole tree can be fed to `json.Marshal`
// unmodified.

type jsonValue = any

// tag0 emits a 0-arg constructor: ["C"].
func tag0(name string) jsonValue { return []jsonValue{name} }

// tag1 emits a 1-arg constructor: ["C", a].
func tag1(name string, a jsonValue) jsonValue { return []jsonValue{name, a} }

// tag2 emits an N-arg (inlined) constructor: ["C", a, b].
func tag2(name string, a, b jsonValue) jsonValue { return []jsonValue{name, a, b} }

// tagTuple2 emits a 1-arg-tuple constructor: ["C", [a, b]].
func tagTuple2(name string, a, b jsonValue) jsonValue {
	return []jsonValue{name, []jsonValue{a, b}}
}

// tagRec emits a constructor whose single argument is an inline record:
// ["C", {fields...}]. Pass an already-constructed map.
func tagRec(name string, rec map[string]jsonValue) jsonValue {
	return []jsonValue{name, rec}
}

// encodeOption encodes `t option`: None -> null, Some x -> x.
func encodeOption(present bool, v jsonValue) jsonValue {
	if !present {
		return nil
	}
	return v
}

// encodeStringList encodes `string list`.
func encodeStringList(xs []string) jsonValue {
	out := make([]jsonValue, 0, len(xs))
	for _, s := range xs {
		out = append(out, s)
	}
	return out
}

# Simple Diff

## Description

Simple Diff is a pure OCaml implementation of a diffing algorithm ported from https://github.com/paulgb/simplediff.

## Usage

`opam install simple-diff`

It exposes only one function, `get_diff`, which expects two arrays of strings. These arrays of strings typically represent lines of a new and old versions of a file. The return value is a list of `diff`s. Below is an example of how to use:

```ocaml
open Simple_diff;;
let old = [| "foo"; "bar"; "baz"; "bin" |];;
let new = [| "bar"; "baz"; "foo"; "bin" |];;
get_diff old new;;
#=> [
  Deleted [| "foo"; "bar"; "baz" |];
  Added [| "bar"; "baz"; "foo" |];
  Equal [| "bin" |]
]
```

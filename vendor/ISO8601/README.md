# ISO8601

[![Build Status](https://travis-ci.org/ocaml-community/ISO8601.ml.svg?branch=master)](https://travis-ci.org/ocaml-community/ISO8601.ml)

ISO 8601 and RFC 3339 date parsing for OCaml.

**Work in progress. API should not be considerer stable
until 1.0.0 version.**

[API Docs](https://ocaml-community.github.io/ISO8601.ml/)

## Permissive module

Date, time, and datetime parsing function of this module are
much more permissive than ISO 8601 or RFC 3339 specifications.

Either basic and/or extended formats can be used for date and time,
and no consistency is required (it is possible to mix basic format for
date and extended format for time), lowercase letters can be used,
and datetime separator may be a space character.

Note: for now, this module is the only one available.

## Installation

Via opam:

    opam install ISO8601

From sources:

    make build
    make install

## License

Distributed under the terms of [MIT license](LISENCE).

Uri -- an RFC3986 URI/URL parsing library
-----------------------------------------

This is an OCaml implementation of the [RFC3986](http://tools.ietf.org/html/rfc3986) specification 
for parsing URI or URLs.

## Installation

### Via OPAM

The [OPAM](https://opam.ocaml.org) package manager can be used to install this library from source.

    opam install uri

### Locally

You can build the source code locally via the [dune](https://github.com/ocaml/dune)
build system.

    opam install uri --deps-only
    eval `opam config env`
    dune build
    dune runtest

will install the dependencies via OPAM, build the library and then run the tests in the [lib_test/](lib_test/) directory.

## Usage

Once installed, there are three ocamlfind packages available for your use:

- `uri` - the base `Uri` module
- `uri-re` - the _legacy_ implementation
  At the beginning, `uri` used `re` to parse a `string`. Since 4.0.0,
  we use `angstrom` - if something breaks with `uri.4.0.0`, you should compare
  with `uri-re` and submit an issue. `uri-re` is deprecated and it will be
  removed on the next release (see #150)
- `uri.top` - the toplevel printers for use with [utop](https://github.com/diml/utop)
- `uri-sexp` - provides converters to and from s-expressions (via a `Uri_sexp.t` type alias)
- `uri.services` - the `Uri_services` module that provides the equivalent of *[services(5)](http://man7.org/linux/man-pages/man5/services.5.html)*
- `uri.services_full` - the `Uri_services_full` module that provides a complete copy of the `/etc/services` file. This is quite large and normally not needed.

## Contact

- Issues: <https://github.com/mirage/ocaml-uri/issues>
- E-mail: <mirageos-devel@lists.xenproject.org>
- API Documentation: <http://docs.mirage.io/uri/>

[![Build Status](https://travis-ci.org/mirage/ocaml-uri.png)](https://travis-ci.org/mirage/ocaml-uri)

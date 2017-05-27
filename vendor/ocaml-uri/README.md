Uri -- an RFC3986 URI/URL parsing library
-----------------------------------------

This is an OCaml implementation of the [RFC3986](http://tools.ietf.org/html/rfc3986) specification 
for parsing URI or URLs.

## Installation

### Via OPAM

The [OPAM](https://opam.ocaml.org) package manager can be used to install this library from source.

    opam install uri

### Locally

You can build the source code locally via the [Jbuilder](https://github.com/janestreet/jbuilder)
build system.

    opam install uri --deps-only
    eval `opam config env`
    jbuilder build --dev
    jbuilder runtest

will install the dependencies via OPAM, build the library and then run the tests in the [lib_test/](lib_test/) directory.

## Usage

Once installed, there are three ocamlfind packages available for your use:

- `uri` - the base `Uri` module
- `uri.top` - the toplevel printers for use with [utop](https://github.com/diml/utop)
- `uri.services` - the `Uri_services` module that provides the equivalent of *[services(5)](http://man7.org/linux/man-pages/man5/services.5.html)*
- `uri.services_full` - the `Uri_services_full` module that provides a complete copy of the `/etc/services` file. This is quite large and normally not needed.

## Contact

- Issues: <https://github.com/mirage/ocaml-uri/issues>
- E-mail: <mirageos-devel@lists.xenproject.org>
- API Documentation: <http://docs.mirage.io/uri/>

[![Build Status](https://travis-ci.org/mirage/ocaml-uri.png)](https://travis-ci.org/mirage/ocaml-uri)

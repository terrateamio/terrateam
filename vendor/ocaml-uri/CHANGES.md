v1.9.6 2018-01-11
-----------------

* Change code generation strategy to avoid big switches in
  the services file; improves build time by 10x (#114 by @gasche).
* Remove deprecated function use (`String.lowercase`)
* Add development Makefile with more targets.

v1.9.5 2017-11-05
-----------------

* Fix build with OCaml 4.06 (and -safe-string) (#108 @hcarty)
* Set (wrapped false) in jbuilder (#105 @avsm)
* Add OCaml 4.06 to the travis CI matrix (#109 @djs55)

v1.9.4 2017-05-30
-----------------

* Port build system to jbuilder (#100 @vbmithr @rgrinberg @avsm @dsheets).
  There should be no observable changes, except that `Uri_services` is now
  in a separate subdirectory. This means that packages that implicitly
  depended on the module without including the ocamlfind `uri.services`
  package may now fail. Just adding the ocamlfind dependency will fix it,
  and is backwards compatible with older Uri releases.
* Restrict build to OCaml 4.03.0+ (was formerly OCaml 4.02.0+).
* Add Appveyor tests for Windows compilation.

v1.9.3 2017-03-06
-----------------

* Port build system to topkg (#95 by @fgimenez)
* Add a tighter opam constraint on `ppx_sexp` (#94)
* Explicitly depend on `ppx_deriving` for improving future compatibility
  with Jane Street upstream (#98).
* Update Travis CI to include OCaml 4.04 and 4.03 in the matrix.

v1.9.2 2016-02-12
-----------------

* Remove sexplib.syntax, `type_conv` deps and camlp4 transitive dependency
* Add `ppx_sexp_conv` dependency
* Require OCaml 4.02.3+

v1.9.1 2015-06-26
-----------------

* Fix `with_password None` when no userinfo present (#78 from Hezekiah M. Carty)

v1.9.0 2015-05-15
-----------------

* Colon (":") is no longer percent-encoded in path segments
* URNs are now supported (#67)
* Relative paths with colons in first segment have "./" prepended in to_string
* Add Uri.empty, the zero length URI reference
* `Uri_services` now includes service aliases (e.g. www, www-http, http)
* `Uri_services` now includes chargen and git
* Add `Uri.canonicalize` for scheme-specific normalization (#70)
* Add `Uri.verbatim_query` to extract literal query string (#57)
* Add `Uri.equal`
* Add `Uri.user` and `Uri.password` accessors for subcomponents of userinfo (#62)
* Add `Uri.with_password` functional setter for password subcomponent of userinfo
* Fix file scheme host normalization bug which introduced empty host (#59)

v1.8.0 2015-02-16
-----------------

* `Uri.with_port` no longer sets the host fragment to a blank value if both
   the host and port are empty (#63).
* `Uri.compare` imposes an ordering by host, scheme, port, userinfo, path,
  query, and finally fragment. (#55).
* Uri is now an `OrderedType` and can be used directly in Maps and Sets (#55).
* Remove deprecation warnings with OCaml 4.02.0+ (#58).
* Drop support for OCaml 3.12.1, and now require OCaml 4.00.1+.
* Modernise Travis scripts to use OPAM 1.2 workflow.

v1.7.2 2014-08-10
-----------------

* Fix empty-but-existing query ("?") parsing bug
* Fix `with_userinfo` against hostless URI representation bug
* Fix `with_port` against hostless URI representation bug
* Fix `with_path` with relative path against hosted URI representation bug (#51)
* Fix `make` without host but with userinfo or port representation bug
* Fix `make` with host, userinfo, or port and relative path representation bug

v1.7.1 2014-07-05
-----------------

* Add RFC6874 compliance for IPv6 literals with zones (#48).

v1.7.0 2014-06-16
-----------------

* Expose the list of known services in the `Uri_services` module via
  new functions that list TCP, UDP and an association list of both.

v1.6.0 2014-04-28
-----------------

* Remove `Uri_IP` module, superseded by the `ipaddr` package (#30).
* Do not depend on `camlp4` for link-time, only compile time (#39).
* Add `with_scheme` and `with_userinfo` functional setters (#40).
* Always percent-escape semicolon in structured query encoding (#44).

v1.5.0 2014-03-24
-----------------

* Make library POSIX thread-safe by removing dependency on `Re_str`.
* Add Merlin IDE configuration.

v1.4.0 2014-02-16
-----------------

* Fix `path` and `path_and_query` encoding bugs (#35).
* Fix userinfo percent-encoding/delimiter bug (#35).
* Add optional scheme parameter to `encoding_of_query`.

v1.3.13 2014-01-16
-----------------

* Remove internal use of Scanf.
* Expose `with sexp` for the Uri types.

v1.3.12 2013-12-28
-----------------

* Be lenient about decoding incorrect encoded percent-strings (#31).
* Improve ocamldoc for `Uri.of_string`.
* Regenerate build files with OASIS 0.4.1.
* Add an `mldylib` to build the cmxs Natdynlink plugin properly (#29).

v1.3.11 2013-10-13
-----------------

* Add relative-relative URI resolution support.
* OCamldoc fixes.
* Add Travis continous build tests.

v1.3.10 2013-09-05
-----------------

* Rename `Install_printer` to `Uri_top` to prevent conflict with other libraries with similar name (#24).

v1.3.9 2013-08-30
-----------------

* Add back support for OCaml 3.12.1 by fixing the compiler-libs linking.

v1.3.8 2013-05-19
-----------------

* Add `Uri.get_query_param` which selects a single value for a query key.
* Add `Uri.get_query_param'` which returns a list of values associated with a query key.
* Fix ocamldoc in `Uri` module to have a header.

v1.3.7 2013-01-23
-----------------

* Add a top-level printer for `Uri.t` that converts it to a string instead
  of just displaying an `<abstract>` type.

v1.3.6 2012-12-29
-----------------

* Add `with_host`, `with_port`, `with_fragment` and `with_host`, to modify
  the respective fields of an input URI.

v1.3.5 2012-12-19
-----------------

* Fix percent encoding of characters from 0x0 to 0xf.
* Add `Uri.remove_query_param` function to remove keys from query sets.

v1.3.4 2012-11-08
-----------------

* Always encode `+` in URLs to be more compatible with form encoding.

v1.3.3 2012-10-14
-----------------

* Add singleton variants of query functions that accept a `string->string`
  instead of a string list of values, for convenience.

v1.3.2 2012-09-20
-----------------

* Fix parsing of unreserved characters in hostnames (e.g. `foo-bar.com`).
* Add unit tests for the `Uri_services` module.
* Various URI parsing bugs and test cases for better RFC3986 compliance.
* Fix `port_of_uri` to detect port overrides in a URI before doing a lookup.

v1.3.1 2012-09-12
-----------------

* Make the `Uri_services_full` library optional, as it takes a loooong time
  to compile. It will return as a UNIX binding to getservent(2) also.

v1.3.0 2012-08-24
-----------------

* Add `Uri_services` to lookup IANA the common well-known ports and services
* Add `Uri_services_full` with a complete database of the IANA database.

v1.2 2012-08-21
---------------

* Add `Uri.path_and_query` to retrieve a path/query combination string.
* Add `Uri.host_with_default` to retrieve a hostname string.

v1.1 2012-08-02
---------------

* Fix query parsing order.
* Improve safe character handling across URI components.

v1.0 2012-08-01
---------------

* Initial public release.

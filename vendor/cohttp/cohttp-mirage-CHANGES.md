### 3.2.0

* Port to jbuilder

### 3.1.0

* Add `Cohttp_mirage_static` module for serving static files from a
  read-only key-value store.  Includes magic mime detection.
* Improve the ocamldoc strings for the modules.
* Constrain supported OCaml version to 4.03.0+ or higher, as with Mirage 3.0.

### 3.0.0 

* Port to MirageOS 3 CHANNEL interface.
* Use Travis Docker for more multidistro testing.

### 2.5.3 (13-06-2016)

* Switch to topkg (#25, @samoht)
* Fix memory leak in the callback when an exception is raised (#24, @hannesm)

### 2.5.2 (13-04-2016)

* Fix memory leak by closing channel when callback is executed
  (#23 via @hannesm)

### 2.5.1 (15-09-2015)

* Add a preapplied server with conduit (#20, by @Drup)

### 2.5.0 (05-07-2015)

* Depends on `channel` instead of the full `tcpip` stack

### 2.4.0 (10-06-2015)

* Support cohttp 0.18 (#13, by @rgrinberg)

### 2.3.0 (29-05-2015)

* Simplify the `Client` signature to be a simple module. It is not
  a functor depending on `Conduit` anymore and the context is now
  more explicit.
* Expose type equalities for `IO.conn` in the `Server` functor
* Adapt to conduit 0.8.4

### 2.2.0: (08-04-2015)

* Do not user `lwt.syntax`
* Rename `HTTP` to `Cohttp_Mirage` (#9)
* Expose `Cohttp_mirage_io`
* Expose a `Server` functor which depends only on mirage's `FLOW` (no dependency
  to `Conduit` anymore in this case)
* Modernize Travis CI scripts

### 2.1.0 (05-12-2014):

* Use the Conduit 0.7+ resolver API (provide `of_sexp` for context).
* Do not link against `camlp4` in the `META` file and only use it during build.

### 2.0.0 (07-11-2014):

* Use the Conduit 0.6+ resolver API.
* Add a local `opam` file for the OPAM 1.2.0 workflow.

### 1.2.0 (03-05-2014):

* Use the Cohttp.0.12.0 interface.

### 1.1.0 (05-02-2014):

* Functorize the HTTP Mirage layer, so that the library is now
  OS-independent and compatible with Mirage 1.1.x signatures.

### 1.0.0 (18-01-2013):

* Initial public release.

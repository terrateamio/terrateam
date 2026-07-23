Cohttp is designed to be an HTTP implementation that is an "onion", with the
portable parsing core progressively introducing I/O, and then higher-level
abstractions for various HTTP operations.  Here's a description of each layer:

- The very first layer (in `lib/`) is a pure OCaml, non-blocking layer that
  handles simple parts of the HTTP protocol such as parsing requests and
  responses, various header parsers (e.g. cookies) and codes.

- Some layers of HTTP need some notion of I/O, and so there is a set of
  signatures in `lib/s.mli` that defines some common module types that can be
  used to build parameterised modules (also known as functors).  The first one
  used in the `lib/` layer is the IO module type, which defines the minimal
  collection of functions used by cooperative threading libraries.  The pure HTTP
  core uses this IO module to capture IO-based operations, such as Transfer_IO
  (for transfer encoding).

- There are three implementations that satisfy the IO module in the tree: Lwt,
  Async and String.  The first two are full cooperative threading libraries,
  and the latter is used by the js_of_ocaml backend to read/write between
  Strings.

- Now that IO has been handled, we can send HTTP requests and responses from
  Lwt or Async.  However, at this point some differences appear in the
  implementations of Async and Lwt, notably in how they handle cancellation of
  threads and also higher-level iterators (e.g. Async has Pipes, and Lwt has
  Lwt_stream -- both quite different).  Therefore, we build backend-specific
  Client and Server modules that use their respective threading libraries in as
  native a style as possible, but still reusing the core HTTP library from
  `lib/`.  These can be found in `Cohttp_lwt` and `Cohttp_async` respectively.
  Dave Scott also wrote an (as yet not merged) POSIX blocking version that they
  use in the XenAPI daemon.

- Lwt comes with an additional twist -- it is portable to both Unix *and* the
  MirageOS, which has no Unix at all!  Lwt makes it possible to define a "Lwt
  core" that uses the portable Lwt thread abstractions, but doesn't use any
  OS-specific functionality.  Thus we can define an HTTP Client and Server in
  Cohttp_lwt, but still not tie ourself to one particular OS.  This Cohttp_lwt is
  then used by the Cohttp_lwt_unix and Cohttp_mirage backends to hook it into the
  operating system.

- There's no commonality at present between Cohttp_async and Cohttp_lwt, but
  that's the topic of a design discussion at the moment.  It should be possible
  to build a common signature between the two. (TODO add issue)

- Andy Ray did something interesting with the Lwt backend: he ported it to
  _javascript_ by implementing an IO backend that marshals the requests to and
  from strings.  This allows REST API users built over Cohttp (such as
  ocaml-github) to compile to pure _javascript_ as well.

Drawbacks:

- The heavy use of functors does make it hard to navigate the 'end user' API,
  even though those interfaces never expose any functors (for instance, you
  just use Cohttp_lwt_unix directly in most cases). This is a drawback of current
  OCaml tooling, and Merlin (for IDEs) and Codoc (for cross-referenced
  documentation) will fix this soon.

- A bigger problem that needs to be addressed in Cohttp2 is body handling,
  which we basically got wrong in this iteration.  The Body module is not
  idempotent, so to_string does not always return the same value if called
  multiple times.  The caller can currently be careful, but this is just an awful
  part of the API.  There are enough users of Cohttp that we'll leave it for 1.0,
  but hopefully fix it quite rapidly for 2.0.

- Cohttp is not a complete HTTP client, and doesn't implement the full logic
  for redirections, loop detection and so on.  That's the job of a library
  built over it, and there is some nascent code in
  [opam-mirror](http://github.com/avsm/opam-mirror) that can do this.  Before
  building this, David Sheets and I want to look at some of the more larger API
  clients built using it (such as Vincent Bernardoff's BitStamp API)
  and take a shot at a portable client API that will work with both Lwt and Async.

Planned changes for 1.0:

* Make the Lwt response stream bounded (new in lwt-2.4+)

Planned changes for 2.0:

* Make the Header.t header parsing more efficient by only lazily parsing them
  instead of copying into a Map as we do now.

Better HTTP support:

- Range requests need to be fully implemented (206)
- 100 Continue should be a noop
- Awwww crap, so much to do : http://www.and.org/texts/server-http
- A client interface that deals with redirects
- Proxy support (manual means a full URI in the request)

Tests:

- Test the lib_test server scripts via external invocations of
  curl and httperf, so that the tests terminate.

- Test the HTTP timeout support

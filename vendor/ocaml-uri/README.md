RFC3968 URI parsing library.

Requires the (`ocaml-re`)[http://github.com/avsm/ocaml-re] regular expression library.

Much assistance for the regular expressions from:
http://jmrware.com/articles/2009/uri_regexp/URI_regex.html

TODO (at least):

* form encoding (' ' to '+'). Python has a `quote_plus` for this as it is different behaviour from normal URL percent encoding.
* query argument decoding
* path normalisation (`a/b/..` to `a/b`)
* relative url resolution

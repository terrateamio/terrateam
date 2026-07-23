
all: build test

build:
	@dune build @install

doc:
	@dune build @doc

test:
	@dune runtest --force --no-buffer

gh-pages: doc
	commitmsg="Documentation for $(VERSION) version." \
	docdir="_build/default/_doc/_html/" \
	upstream="origin" \
	ghpup

clean:
	@dune clean

.PHONY: test build clean

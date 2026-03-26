## Installation

This project uses [opam](https://opam.ocaml.org/), but not [dune](https://dune.build/). That is why the setup is slightly unusual,
but because it is simple; it's easy to setup if you're thorough. If these instructions do not work, check out
[docker/terrat/Dockerfile](./docker/terrat/Dockerfile) as this file contains a similar workflow, but may be updated more often (search for `opam env`).

First create a local opam switch as follows (execute this from the repository's root):

```shell
opam switch create -y 5.3.0 --no-depexts
eval $(opam env)
opam pin add -y cmdliner 1.3.0
opam pin add -y containers 3.12
opam pin add -y cmdliner 1.3.0
```

Now we want to reach this state:

```
→ opam repository
[NOTE] These are the repositories in use by the current switch. Use '--all' to see all configured repositories.

<><> Repository configuration for switch /home/tamiya/dev/terrateam <><><><><>
 1 tt-opam-mono file:///home/tamiya/dev/terrateam/opam-mono
 2 tt-opam-acsl file:///home/tamiya/dev/terrateam/opam
 3 default      https://opam.ocaml.org
```

Execute the following:

```shell
opam repository add tt-opam-acsl opam
opam pin add -y pds 6.54 --no-depexts
opam pin add -y hll 4.3 --no-depexts
mkdir -p opam-mono/compilers opam-mono/packages
echo 'opam-version: "2.0"' > opam-mono/repo
opam repository add tt-opam-mono opam-mono
```

Now inside the `code` directory:

```
cd code
hll generate -n monorepo --opam-dir ../opam-mono --tag 1.0 --test-deps-as-regular-deps --url-override file://$PWD
opam update tt-opam-mono
opam info monorepo
ulimit -s 524288 && ulimit -a && pds -d && time make -j$(nproc --all) test test-terrat release-terrat release-ttm
opam install ocaml-lsp-server ocamlformat-rpc dot-merlin-reader
```

Then make sure the right flag is passed to the LSP server (if you're using vscode), so put the following:

```
cat code/.vscode/settings.json 
{
  "ocaml.server.args": [ "--fallback-read-dot-merlin" ],
}
```

Finally, execute the following for internal dependencies to be found by the LSP:

```shell
make .merlin
```

Now, launching `vscode` from the [code](./code) directory, within a shell augmented with the output of `opam env`
(e.g. execute `eval $(opam env)` in your shell) should provide you with the usual features (symbol linking, jump to definition, etc.).
If not, create an issue, and assign it to [@tamiyasigmar](https://github.com/tamiyasigmar)!

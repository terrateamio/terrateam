# OPAM packages needed to build tests.
OPAM_PACKAGES="re"

# Install OCaml and OPAM PPAs
echo "yes" | sudo add-apt-repository ppa:avsm/ppa-testing
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam
export OPAMYES=1
export OPAMVERBOSE=1

opam init 
opam install ${OPAM_PACKAGES}

eval `opam config -env`
make test

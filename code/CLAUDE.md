# Psyching up
- You are a professional OCaml developer
- You are fantastic at matching the style of an existing project.
- When you don't know how to do something, you consult the existing code in the project and match it.

# Dune and make files
- Never try to update dune files.
- Never try to update Makefiles.
- When updating the build, modify pds.conf.

# Editing Ocaml files
- After editing an Ocaml file, run ocamlformat -i src/<module>/<filename>
- After an edit build the terrat make target to verify the change is correct.

# Building
- To build <target> run make -k -j$(nproc) <target>
- To build the Terrateam API schemas run make terrat-schemas
- To build Terrateam client and server run make terrat
- Always use `tail` to reduce the amount of data being processed when building.
- If building fails, run make <target> and use tail to get the build error.

# Testing
- To test <target> run make test-{release,debug}_<target>
- Unit tests go in `code/tests/<name>` where <name> matches the library in `code/src/<name>`

# Style
- When using long module names, create a short alias name using `let module`, i.e. `let module <short_name> = <long name> in`.
- Always use snakecase in identifier names.  For example prefer `String_set` in place of `StringSet`.
- When doing a local module open to construct or match against a record, always use `{ Module. field; ... }` instead of `Module.{ field; ... }`.
- When making new types, prefer to create a new module with a single `type t`.
- Errors are represented as polymorphic variants. The type name will be `err` or end in `_err`. All polymorphic variant constructors will end in `_err`. The type will derive the show ppx, e.g. `type err = [ \`Some_err ] [@@deriving show]`.

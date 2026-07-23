# CHANGELOG

## 0.2.6

- migration to ocaml-community
- move to dune
- update travis build to use Docker
- Merge branch 'test' into master, use dune for tests

## 0.2.5

- Added unix requirement in META file

## 0.2.4

- "pp_format: the 'minute' specifier is now modulo 60"
  (patch by Erkki Seppälä)

## 0.2.3

- Fixed zero padding when printing time zone offset.

## 0.2.2

- Fixed "Warning 40: tm_isdst was selected from type Unix.tm"

## 0.2.1

- Fixing the previous important bugfix. (!)
- Fixing the daylight time saving offset in timestamp.

## 0.2.0

- Breaking change in API: functions with optionnal time zone
  argument splitted into 2 different functions. With and without
  time zone argument.
- Used format-like function to be able to customize printing.
- Added printers for basic format.
- Important bugfix when using mktime.

## 0.1.3

- Printer bugfix.

## 0.1.2

- Printer bugfix.

## 0.1.1

- Fixed OCaml 3.12.1 compatibility.

## 0.1.0

- Permissive module will parse a superset of (a part of)
  the ISO8601 spec.
- Printing of date / times / ... with the form defined as
  the extended format.

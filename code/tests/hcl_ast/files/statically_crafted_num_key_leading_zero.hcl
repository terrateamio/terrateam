# Object key with a leading-zero integer. Menhir lexes as INTEGER,
# then `string_of_int` discards the leading zeros; the shim uses raw
# source bytes (preserving `007`).
x = {
  007 = "a"
  0042 = "b"
  0 = "c"
}

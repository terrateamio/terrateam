# Integer key overflow — key that's an integer beyond int64 range.
# Shim keeps raw source bytes; Menhir may truncate or render differently.
x = {
  123456789012345678 = "a"
  9999999999999999999 = "b"
}

x = {
  v1                                  = 1
  (v2)                                = 2
  "v3"                                = 3
  (v4.foo)                            = 4
  "v5.foo"                            = 5
  "${path.module}literal${local.foo}" = 6
  3 + 4                               = 7
  (3 + 4)                             = 8
  ((3 + 4))                           = 9
  v5.foo                              = 10
  "foo$${bar}"                        = 11
}
resource "example" "test" {
  simple = foo.bar[0]
  multiline_index = some_map[
    "key"
  ]
  multiline_splat = some_list[
    *
  ]
  chained = some_map[
    "key"
  ].name
}

val convert :
  strict_records:bool ->
  search_path:string list ->
  file_link:(string * string) list ->
  input_file:string ->
  output_name:string ->
  output_dir:string ->
  unit

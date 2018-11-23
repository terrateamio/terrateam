include module type of Snabela

val render_string :
  ?transformers:Transformer.t list ->
  string ->
  Kv.t Kv.Map.t ->
  (string, [> err | Template.err ]) result

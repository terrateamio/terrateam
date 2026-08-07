greeting = "Hello, %{ if name != "" }${name}%{ else }stranger%{ endif }!"
status   = "%{ if enabled }active%{ endif }"
verdict  = "%{ if score > 0 }pass%{ else }fail%{ endif }"

# Strip markers on the directive opener: all four combinations.
strip_both    = "%{~ if cond ~}yes%{ endif }"
strip_before  = "%{~ if cond }yes%{ endif }"
strip_after   = "%{ if cond ~}yes%{ endif }"
strip_neither = "%{ if cond }yes%{ endif }"

# Strip markers on interpolations inside the if branches.
nested_interp = "%{ if cond }${~ x ~}%{ else }${~ y }${z~}%{ endif }"

# Strip markers on the opener AND on an inner interpolation.
combo = "%{~ if ready ~}${~ name ~}%{ else }fallback%{ endif }"

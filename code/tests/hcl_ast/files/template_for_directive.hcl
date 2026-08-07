list   = "%{ for item in items }${item}, %{ endfor }"
pairs  = "%{ for k, v in map }${k}=${v}; %{ endfor }"

# Strip markers on the directive opener: all four combinations.
strip_both    = "%{~ for x in xs ~}${x}%{ endfor }"
strip_before  = "%{~ for x in xs }${x}%{ endfor }"
strip_after   = "%{ for x in xs ~}${x}%{ endfor }"
strip_neither = "%{ for x in xs }${x}%{ endfor }"

# Strip markers on interpolations inside the body.
body_interp = "%{ for k, v in map }${~ k ~}=${v~}; %{ endfor }"

# Two-variable form with strip markers on the opener and every interpolation.
pairs_stripped = "%{~ for k, v in map ~}${~ k ~}=${~ v ~}; %{ endfor }"
